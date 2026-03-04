import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Encrypted storage - images never in Photo Gallery
/// Uses platform Keychain (iOS) / EncryptedSharedPreferences (Android)
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();

  Future<void> writeJson(String key, Map<String, dynamic> data) =>
      write(key, jsonEncode(data));

  Future<Map<String, dynamic>?> readJson(String key) async {
    final s = await read(key);
    if (s == null) return null;
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Auth tokens
  Future<void> saveOfflineToken(String token) =>
      write(AppConstants.keyOfflineToken, token);

  Future<String?> getOfflineToken() => read(AppConstants.keyOfflineToken);

  Future<void> saveAuthToken(String token) =>
      write(AppConstants.keyAuthToken, token);

  Future<String?> getAuthToken() => read(AppConstants.keyAuthToken);

}
