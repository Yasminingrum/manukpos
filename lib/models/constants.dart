// config/constants.dart
class AppConstants {
  // App Information
  static const String appName = 'MANUK';
  static const String appVersion = '1.0.0';
  static const String appCopyright = '© 2025 MANUK - Manajemen Keuangan UMKM';
  
  // API Configuration
  static const String apiBaseUrl = 'https://documenter.getpostman.com/view/37267696/2sB2ca8L6X';
  static const int apiTimeout = 30; // in seconds
  
  // Local Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String branchKey = 'current_branch';
  static const String settingsKey = 'app_settings';
  
  // Default Values
  static const int defaultPageSize = 20;
  static const double defaultTaxRate = 0.11; // 11% PPN
  
  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableAutoSync = true;
  static const bool enablePushNotifications = false;
  
  // Time Constants
  static const int syncIntervalMinutes = 15;
  static const int sessionTimeoutMinutes = 30;
}