// config/constants.dart
class AppConstants {
  // App Information
  static const String appName = 'MANUK';
  static const String appVersion = '1.0.0';
  static const String appCopyright = '© 2025 MANUK - Manajemen Keuangan UMKM';
  
  // API Configuration
  static const String apiBaseUrl = 'https://documenter.getpostman.com/view/37267696/2sB2ca8L6X';
  static const int apiTimeout = 30; // in seconds
  
  // Database Constants
  static const String dbName = 'manuk_pos.db';
  static const int dbVersion = 1;
  static const bool enableForeignKeys = true;
  static const String dbBackupDir = 'backup';

  // Local Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String branchDataKey = 'branch_data';
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
  
  // Database Tables
  static const String tableUsers = 'users';
  static const String tableBranches = 'branches';
  static const String tableProducts = 'products';
  static const String tableCategories = 'categories';
  static const String tableInventory = 'inventory';
  static const String tableInventoryTransactions = 'inventory_transactions';
  static const String tableTransactions = 'transactions';
  static const String tableTransactionItems = 'transaction_items';
  static const String tableCustomers = 'customers';
  static const String tablePayments = 'payments';
  static const String tableSyncLog = 'sync_log';
  
  // Sync Status
  static const String syncStatusPending = 'pending';
  static const String syncStatusCompleted = 'completed';
  static const String syncStatusFailed = 'failed';
}