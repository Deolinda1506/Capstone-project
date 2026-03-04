import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Encrypted storage for scan images
/// Images never appear in Photo Gallery - stored in app-private directory
/// TODO: Add encryption layer (e.g. encrypt package) for additional security
class EncryptedImageStorage {
  static Future<Directory> get _appDir async {
    final dir = await getApplicationDocumentsDirectory();
    final secureDir = Directory('${dir.path}/carotid_secure');
    if (!await secureDir.exists()) {
      await secureDir.create(recursive: true);
    }
    return secureDir;
  }

  /// Save image to app-private folder (not in gallery)
  static Future<File> saveImage(File source, String userId, DateTime timestamp) async {
    final dir = await _appDir;
    final name = 'scan_${timestamp.millisecondsSinceEpoch}_${userId.hashCode}.dat';
    final dest = File('${dir.path}/$name');
    await source.copy(dest.path);
    return dest;
  }

  /// Watermark metadata (User ID + Timestamp) - stored alongside image
  static Future<void> saveWatermark(File imageFile, String userId, DateTime timestamp) async {
    final metaFile = File('${imageFile.path}.meta');
    await metaFile.writeAsString('$userId|${timestamp.toIso8601String()}');
  }
}
