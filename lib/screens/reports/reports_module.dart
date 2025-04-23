// lib/modules/reports_module.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/reports/sales_report.dart';
import '../../screens/reports/expense_report.dart';
import '../../screens/reports/inventory_report.dart';
import '../../screens/reports/financial_report.dart';
import '../../services/transaction_service.dart';
import '../../services/expense_service.dart';
import '../../services/inventory_service.dart';
import '../../services/product_service.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';
import '../../config/constants.dart';

/// Reports module for the MANUK POS application
class ReportsModule {
  /// Register all report-related dependencies
  static List<Provider> registerProviders() {
    return [
      // Core services that the reports rely on
      Provider<DatabaseService>(
        create: (_) => DatabaseService(),
      ),
      Provider<TransactionService>(
        create: (_) => TransactionService(),
      ),
      Provider<InventoryService>(
        create: (_) => InventoryService(),
      ),
      Provider<ApiService>(
        create: (_) => ApiService(baseUrl: AppConstants.apiBaseUrl),
      ),
      // Dependent services - created as separate Provider instances
      Provider<ProductService>(
        create: (context) => ProductService(
          apiService: Provider.of<ApiService>(context, listen: false),
          databaseService: Provider.of<DatabaseService>(context, listen: false),
        ),
      ),
      Provider<ExpenseService>(
        create: (context) => ExpenseService(
          apiService: Provider.of<ApiService>(context, listen: false),
          databaseService: Provider.of<DatabaseService>(context, listen: false),
        ),
      ),
    ];
  }
  
  /// Register all report-related routes
  static Map<String, WidgetBuilder> registerRoutes() {
    return {
      '/reports/sales': (context) => const SalesReport(),
      '/reports/expenses': (context) => const ExpenseReportScreen(),
      '/reports/inventory': (context) => const InventoryReportScreen(),
      '/reports/financial': (context) => const FinancialReport(),
    };
  }
  
  /// Create drawer menu items for reports section
  static List<Widget> createDrawerMenuItems(BuildContext context) {
    return [
      const Divider(),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          'REPORTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.shopping_cart),
        title: const Text('Sales Report'),
        onTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.pushNamed(context, '/reports/sales');
        },
      ),
      ListTile(
        leading: const Icon(Icons.money_off),
        title: const Text('Expense Report'),
        onTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.pushNamed(context, '/reports/expenses');
        },
      ),
      ListTile(
        leading: const Icon(Icons.inventory_2),
        title: const Text('Inventory Report'),
        onTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.pushNamed(context, '/reports/inventory');
        },
      ),
      ListTile(
        leading: const Icon(Icons.account_balance),
        title: const Text('Financial Report'),
        onTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.pushNamed(context, '/reports/financial');
        },
      ),
    ];
  }
  
  /// Initialize reports module in database (if needed)
  static Future<void> initializeDatabaseTables(DatabaseService databaseService) async {
    // No special tables needed specifically for reports
    // as we're using data from existing tables
  }
  
  /// Register in the main app
  static void initialize(BuildContext context) {
    // This method could be called during app initialization
    // to ensure all report-related services are properly initialized
    
    // For example, preload some report data in the background
    _preloadReportData(context);
  }
  
  /// Preload some common report data in the background
  static Future<void> _preloadReportData(BuildContext context) async {
    try {
      // Get required services safely
      TransactionService? transactionService;
      ProductService? productService;
      
      try {
        transactionService = Provider.of<TransactionService>(context, listen: false);
        productService = Provider.of<ProductService>(context, listen: false);
      } catch (e) {
        debugPrint('Error getting services: $e');
        return;
      }
      
      // Load in background without blocking UI
      Future.microtask(() async {
        try {
          // Check if services are valid before calling their methods
          if (transactionService != null) {
            await transactionService.getInventoryItems(
              branchId: AppConstants.branchDataKey,
              limit: 10
            );
          }
          
          if (productService != null) {
            await productService.getProducts(limit: 20);
          }
        } catch (e) {
          debugPrint('Error in preloading background task: $e');
        }
      });
    } catch (e) {
      // Silently handle errors in background preloading
      debugPrint('Error preloading report data: $e');
    }
  }
  
  /// Check user permissions for accessing reports
  static bool canAccessReports(String userRole) {
    // Define which user roles can access reports
    const allowedRoles = ['admin', 'owner', 'manager'];
    return allowedRoles.contains(userRole.toLowerCase());
  }
  
  /// Get export formats supported by reports
  static List<Map<String, dynamic>> getSupportedExportFormats() {
    return [
      {
        'id': 'excel',
        'name': 'Microsoft Excel',
        'extension': '.xlsx',
        'icon': Icons.table_chart,
        'color': Colors.green,
      },
      {
        'id': 'pdf',
        'name': 'PDF Document',
        'extension': '.pdf',
        'icon': Icons.picture_as_pdf,
        'color': Colors.red,
      },
      {
        'id': 'csv',
        'name': 'CSV File',
        'extension': '.csv',
        'icon': Icons.insert_drive_file,
        'color': Colors.blue,
      },
    ];
  }
}