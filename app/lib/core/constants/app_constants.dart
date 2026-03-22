
class AppConstants {
  AppConstants._();

  // Sync status
  static const String syncOffline = 'offline';
  static const String syncPending = 'pending';
  static const String syncSynced = 'synced';

  // Storage keys
  static const String keyAuthToken = 'auth_token';
  static const String keyOfflineToken = 'offline_token';
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';
  static const String keyUserData = 'user_data';
  static const String keySyncStatus = 'sync_status';
  static const String keyCachedPasswordHash = 'cached_password_hash';
}
