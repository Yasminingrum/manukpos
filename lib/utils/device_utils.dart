// lib/utils/device_utils.dart
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

/// Utility class for device information and operations
class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  
  /// Get device ID
  static Future<String> getDeviceId() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      return info.id;
    } else if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      return info.identifierForVendor ?? 'unknown';
    }
    return 'unknown';
  }
  
  /// Get device name
  static Future<String> getDeviceName() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      return '${info.brand} ${info.model}';
    } else if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      return info.name;
    }
    return 'unknown';
  }
  
  /// Get app version
  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
  
  /// Get build number
  static Future<String> getBuildNumber() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildNumber;
  }
  
  /// Get app name
  static Future<String> getAppName() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.appName;
  }
  
  /// Get package name
  static Future<String> getPackageName() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.packageName;
  }
  
  /// Get platform name
  static String getPlatformName() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    }
    return 'unknown';
  }
  
  /// Get platform version
  static Future<String> getPlatformVersion() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      return info.version.release;
    } else if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      return info.systemVersion;
    }
    return 'unknown';
  }
  
  /// Check if device is tablet
  static Future<bool> isTablet() async {
    if (Platform.isAndroid) {
      // Use a simpler approach based on device model naming conventions
      final info = await _deviceInfoPlugin.androidInfo;
      final String model = info.model.toLowerCase();
      final String brand = info.brand.toLowerCase();
      
      // Check common tablet indicators in device names
      if (brand.contains('samsung') && 
          (model.contains('tab') || model.contains('note'))) {
        return true;
      }
      
      if (brand.contains('huawei') && model.contains('mediapad')) {
        return true;
      }
      
      if (brand.contains('lenovo') && 
          (model.contains('tab') || model.contains('yoga'))) {
        return true;
      }
      
      if (brand.contains('asus') && model.contains('zenpad')) {
        return true;
      }
      
      if (model.contains('tablet') || model.contains('pad')) {
        return true;
      }
      
      // For unknown devices, we'll have to rely on device characteristics
      // that don't use the problematic properties
      
      // Most phones have a model name that includes "phone" or specific model series
      if (model.contains('phone') || 
          model.contains('pixel') || 
          model.contains('galaxy s') || 
          model.contains('oneplus')) {
        return false;
      }
      
      // Default to phone assumption if we can't determine
      return false;
    } else if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      return info.model.toLowerCase().contains('ipad');
    }
    return false;
  }
  
  /// Check if app is in debug mode
  static bool isDebugMode() {
    return !const bool.fromEnvironment('dart.vm.product');
  }
  
  /// Get device orientation
  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }
  
  /// Get screen size
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }
  
  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  
  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  
  /// Get safe area insets
  static EdgeInsets getSafeAreaInsets(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
}