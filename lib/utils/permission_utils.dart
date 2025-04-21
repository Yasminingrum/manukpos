// lib/utils/permission_utils.dart
import 'package:permission_handler/permission_handler.dart';

/// Utility class for handling permissions
class PermissionUtils {
  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage permission
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Request location permission
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  /// Check if storage permission is granted
  static Future<bool> hasStoragePermission() async {
    return await Permission.storage.isGranted;
  }

  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    return await Permission.location.isGranted;
  }

  /// Open app settings
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
