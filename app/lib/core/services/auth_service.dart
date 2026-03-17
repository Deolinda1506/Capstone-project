import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/location_model.dart';
import 'api_client.dart';
import 'secure_storage_service.dart';

/// Auth via backend API (email + password)
class AuthService extends ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();
  final ApiClient _api = ApiClient(baseUrl: ApiConfig.baseUrl);

  UserModel? _currentUser;
  String? _authToken;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isAuthenticated => _currentUser != null && _authToken != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _storage.getOfflineToken();
      final userJson = await _storage.readJson(AppConstants.keyUserData);
      if (token != null && userJson != null) {
        _authToken = token;
        _currentUser = UserModel.fromJson(userJson);
        _api.setToken(token);
        _api.onUnauthorized = _handleUnauthorized;
      }
    } catch (_) {
      _authToken = null;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleUnauthorized() {
    logout();
  }

  ApiClient get api => _api;

  Future<bool> register(String password, String fullName, {required String districtId}) async {
    final id = await registerWithId(password, fullName, districtId: districtId);
    return id != null;
  }

  /// Register and return assigned CHW ID (e.g. 0102-001) or null on failure.
  /// approvalCode: from district supervisor (required when backend has APPROVAL_CODES set).
  /// Optional phone: sends ID via SMS and prevents duplicate accounts.
  /// Optional email: sends ID via email.
  Future<String?> registerWithId(
    String password,
    String fullName, {
    required String districtId,
    String? approvalCode,
    String? phone,
    String? email,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      if (password.length < 6) {
        _error = 'Password must be at least 6 characters';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final res = await _api.register(
        password: password,
        displayName: fullName,
        districtId: districtId,
        approvalCode: approvalCode?.trim().isEmpty ?? true ? null : approvalCode?.trim(),
        phone: phone?.trim().isEmpty ?? true ? null : phone?.trim(),
        email: email?.trim().isEmpty ?? true ? null : email?.trim(),
      );

      if (res.success && res.data != null) {
        _authToken = res.data!['access_token'] as String?;
        final userData = res.data!['user'] as Map<String, dynamic>?;
        if (userData != null && _authToken != null) {
          _currentUser = _userFromBackend(userData);
          _api.setToken(_authToken);
          _api.onUnauthorized = _handleUnauthorized;
          await _storage.saveOfflineToken(_authToken!);
          await _storage.saveAuthToken(_authToken!);
          await _storage.writeJson(AppConstants.keyUserData, _currentUser!.toJson());
        }
        final assignedId = userData?['staff_id'] as String?;
        _isLoading = false;
        notifyListeners();
        return assignedId;
      }
      _error = res.error ?? 'Registration failed';
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> login(String identifier, String password) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.login(identifier, password);

      if (res.success && res.data != null) {
        _authToken = res.data!['access_token'] as String?;
        final userData = res.data!['user'] as Map<String, dynamic>?;
        if (userData != null && _authToken != null) {
          _currentUser = _userFromBackend(userData);
          _api.setToken(_authToken);
          _api.onUnauthorized = _handleUnauthorized;
          await _storage.saveOfflineToken(_authToken!);
          await _storage.saveAuthToken(_authToken!);
          await _storage.writeJson(AppConstants.keyUserData, _currentUser!.toJson());
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = res.error ?? 'Invalid District ID or password';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  UserModel _userFromBackend(Map<String, dynamic> u) {
    final role = (u['role'] as String? ?? 'chw').toLowerCase();
    return UserModel(
      id: u['id'] as String,
      fullName: u['display_name'] as String? ?? u['email'] as String?,
      role: UserRole.fromString(role),
      status: AccountStatus.fromString(u['status'] as String? ?? 'approved'),
      healthCenter: const LocationModel(
        province: 'Kigali City',
        district: 'Gasabo',
        sector: 'Kimironko',
        healthCenter: 'Gasabo District Hospital',
        village: null,
      ),
      villageId: u['facility'] as String?,
    );
  }

  Future<void> logout() async {
    _currentUser = null;
    _authToken = null;
    _error = null;
    _api.setToken(null);
    _api.onUnauthorized = null;
    await _storage.delete(AppConstants.keyAuthToken);
    await _storage.delete(AppConstants.keyOfflineToken);
    await _storage.delete(AppConstants.keyUserData);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
