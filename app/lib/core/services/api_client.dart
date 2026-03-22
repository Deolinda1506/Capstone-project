import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Backend API client for CarotidCheck
class ApiClient {
  ApiClient({String? baseUrl}) : _baseUrl = (baseUrl ?? 'http://localhost:8000').replaceAll(RegExp(r'/$'), '');

  final String _baseUrl;
  String? _token;

  void Function()? onUnauthorized; // 401 -> clear auth, go to login

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers {
    final h = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (_token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  Future<ApiResponse<T>> _request<T>(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
    Uint8List? fileBytes,
    String? fileField,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final h = {..._headers, ...?headers};

      http.Response response;
      if (fileBytes != null && fileField != null) {
        final request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = _token != null ? 'Bearer $_token' : '';
        request.headers['Accept'] = 'application/json';
        request.files.add(http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: 'scan.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
        if (body is Map) {
          for (final e in (body as Map<String, dynamic>).entries) {
            request.fields[e.key] = e.value?.toString() ?? '';
          }
        }
        final streamed = await request.send();
        // ML inference can take 60–90s; use 2 min timeout for scan upload
        response = await http.Response.fromStream(streamed).timeout(
          const Duration(seconds: 120),
          onTimeout: () => throw Exception('Scan upload timed out (120s). ML inference may still be running.'),
        );
      } else {
        switch (method) {
          case 'GET':
            response = await http.get(uri, headers: h);
            break;
          case 'POST':
            response = await http.post(uri, headers: h, body: body != null ? jsonEncode(body) : null);
            break;
          case 'PATCH':
            response = await http.patch(uri, headers: h, body: body != null ? jsonEncode(body) : null);
            break;
          case 'DELETE':
            response = await http.delete(uri, headers: h);
            break;
          default:
            response = await http.post(uri, headers: h, body: body != null ? jsonEncode(body) : null);
        }
      }

      final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>(success: true, data: decoded as T?, statusCode: response.statusCode);
      }
      if (response.statusCode == 401 && _token != null) {
        onUnauthorized?.call();
      }
      final msg = decoded is Map ? (decoded['detail'] ?? response.body) : response.body;
      return ApiResponse<T>(success: false, error: msg.toString(), statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse<T>(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> login(String identifier, String password) =>
      _request('POST', '/auth/login', body: {'identifier': identifier, 'password': password});

  Future<ApiResponse<Map<String, dynamic>>> forgotPassword(String email) =>
      _request('POST', '/auth/forgot-password', body: {'email': email});

  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String token,
    required String newPassword,
  }) =>
      _request('POST', '/auth/reset-password', body: {
        'token': token,
        'new_password': newPassword,
      });

  Future<ApiResponse<Map<String, dynamic>>> register({
    required String password,
    String? displayName,
    required String districtId,
    String role = 'chw',
    String? approvalCode,
    String? phone,
    String? email,
  }) =>
      _request('POST', '/auth/register', body: {
        'password': password,
        'display_name': displayName,
        'district_id': districtId,
        'role': role,
        if (approvalCode != null && approvalCode.isNotEmpty) 'approval_code': approvalCode,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
      });

  Future<ApiResponse<Map<String, dynamic>>> createPatient({
    String? identifier,
    String? email,
    String? facility,
  }) =>
      _request('POST', '/patients', body: {
        if (identifier != null && identifier.isNotEmpty) 'identifier': identifier,
        if (email != null && email.isNotEmpty) 'email': email,
        if (facility != null) 'facility': facility,
      });

  Future<ApiResponse<List<dynamic>>> listPatients() =>
      _request('GET', '/patients');

  Future<ApiResponse<Map<String, dynamic>>> uploadScan(
    String patientId,
    Uint8List imageBytes, {
    int? patientAge,
  }) {
    final body = <String, dynamic>{'patient_id': patientId};
    if (patientAge != null) body['patient_age'] = patientAge;
    return _request('POST', '/scans/upload', body: body, fileBytes: imageBytes, fileField: 'file');
  }

  Future<ApiResponse<List<dynamic>>> listScans({String? patientId}) {
    final q = patientId != null ? '?patient_id=$patientId' : '';
    return _request('GET', '/scans$q');
  }

  Future<ApiResponse<List<dynamic>>> listScansWithResults({int limit = 50}) =>
      _request('GET', '/scans/with-results?limit=$limit');

  /// High-risk referrals for hospital dashboard (clinicians see all, CHWs see own)
  Future<ApiResponse<List<dynamic>>> listHighRiskReferrals({int limit = 50}) =>
      _request('GET', '/scans/high-risk?limit=$limit');

  /// Fetch result and metadata for a single scan. Enables result screen to survive reload.
  Future<ApiResponse<Map<String, dynamic>>> getScanResult(String scanId) =>
      _request('GET', '/scans/$scanId/result');

  /// Fetch stored scan image (overlay) for clinician review. Returns base64 PNG string.
  Future<ApiResponse<String>> getScanImage(String scanId) async {
    try {
      final uri = Uri.parse('$_baseUrl/scans/$scanId/image');
      final h = <String, String>{'Accept': 'image/png'};
      if (_token != null) h['Authorization'] = 'Bearer $_token';
      final response = await http.get(uri, headers: h);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final b64 = base64Encode(response.bodyBytes);
        return ApiResponse<String>(success: true, data: b64);
      }
      if (response.statusCode == 401 && _token != null) onUnauthorized?.call();
      return ApiResponse<String>(success: false, error: response.body);
    } catch (e) {
      return ApiResponse<String>(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> health() =>
      _request('GET', '/health');
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({required this.success, this.data, this.error, this.statusCode});
}
