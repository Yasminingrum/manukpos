// config/routes.dart
import 'package:flutter/material.dart';
import 'package:manukpos/screens/transactions/purchasing_screen.dart';

// Auth Screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';

// Main Screens
import '../screens/dashboard/dashboard_screen.dart';

// Transaction Screens
import '../screens/transactions/pos_screen.dart';
import '../screens/transactions/history_screen.dart';
import '../screens/transactions/transaction_detail_screen.dart';

// Inventory Screens
import '../screens/inventory/product_list.dart';
import '../screens/inventory/product_detail.dart';
import '../screens/inventory/product_form.dart';
import '../screens/inventory/category_list.dart';
import '../screens/inventory/stock_opname.dart';

// Customer & Supplier Screens
import '../screens/customers/customer_list.dart';
import '../screens/customers/customer_detail.dart';
import '../screens/customers/customer_form.dart';
import '../screens/suppliers/supplier_list.dart';
import '../screens/suppliers/supplier_detail.dart';
import '../screens/suppliers/supplier_form.dart';

// Reports Screens
import '../screens/reports/sales_report.dart';
import '../screens/reports/inventory_report.dart';
import '../screens/reports/financial_report.dart';

// Settings Screens
import '../screens/settings/business_profile.dart';
import '../screens/settings/user_management.dart';
import '../screens/settings/app_settings.dart';

// Models
import '../models/customer.dart';
import '../models/supplier.dart';

// Services
import '../services/database_service.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  
  // Transaction routes
  static const String pos = '/pos';
  static const String purchasing = '/purchasing';
  static const String transactionHistory = '/transactions';
  static const String transactionDetail = '/transactions/detail';
  
  // Inventory routes
  static const String products = '/products';
  static const String productDetail = '/products/detail';
  static const String productForm = '/products/form';
  static const String categories = '/categories';
  static const String stockOpname = '/stock-opname';
  static const String inventoryMovements = '/inventory/movements';
  
  // Customer & Supplier routes
  static const String customers = '/customers';
  static const String customerDetail = '/customers/detail';
  static const String customerForm = '/customers/form';
  static const String suppliers = '/suppliers';
  static const String supplierDetail = '/suppliers/detail';
  static const String supplierForm = '/suppliers/form';
  
  // Report routes
  static const String salesReport = '/reports/sales';
  static const String inventoryReport = '/reports/inventory';
  static const String financialReport = '/reports/financial';
  
  // Settings routes
  static const String businessProfile = '/settings/business';
  static const String userManagement = '/settings/users';
  static const String appSettings = '/settings/app';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      
      case pos:
        return MaterialPageRoute(builder: (_) => const PosScreen());
      
      case purchasing:
        return MaterialPageRoute(builder: (_) => const PurchasingScreen());
      
      case transactionHistory:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      
      case transactionDetail:
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transactionId: args)
          );
        }
        return _errorRoute();
      
      case products:
        return MaterialPageRoute(builder: (_) => const ProductListScreen());
      
      case productDetail:
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: args)
          );
        }
        return _errorRoute();
      
      case productForm:
        int? productId;
        if (args != null && args is int) {
          productId = args;
        }
        return MaterialPageRoute(
          builder: (_) => ProductFormScreen(
            isEditing: productId != null, 
            productId: productId
          )
        );
      
      case categories:
        return MaterialPageRoute(builder: (_) => const CategoryListScreen());
      
      case stockOpname:
        return MaterialPageRoute(builder: (_) => const StockOpnameScreen());
        
      case inventoryMovements:
        return _errorRoute();
      
      case customers:
        return MaterialPageRoute(builder: (_) => const CustomerListScreen());
      
      case customerDetail:
        if (args is int) {
          // Menggunakan FutureBuilder untuk mengambil data customer terlebih dahulu
          return MaterialPageRoute(
            builder: (context) {
              return FutureBuilder<Customer?>(
                future: _getCustomerById(args),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Error')),
                      body: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  }
                  
                  if (!snapshot.hasData) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Customer Not Found')),
                      body: const Center(child: Text('Customer tidak ditemukan')),
                    );
                  }
                  
                  return CustomerDetailScreen(customer: snapshot.data!);
                },
              );
            },
          );
        }
        return _errorRoute();
      
      case customerForm:
        // CustomerFormScreen dapat menerima parameter opsional
        return MaterialPageRoute(
          builder: (_) => const CustomerFormScreen()
        );
      
      case suppliers:
        return MaterialPageRoute(builder: (_) => const SupplierListScreen());
      
      case supplierDetail:
        if (args is int) {
          // Menggunakan FutureBuilder untuk mengambil data supplier terlebih dahulu
          return MaterialPageRoute(
            builder: (context) {
              return FutureBuilder<Supplier?>(
                future: _getSupplierById(args),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Error')),
                      body: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  }
                  
                  if (!snapshot.hasData) {
                    return Scaffold(
                      appBar: AppBar(title: const Text('Supplier Not Found')),
                      body: const Center(child: Text('Supplier tidak ditemukan')),
                    );
                  }
                  
                  return SupplierDetailScreen(supplier: snapshot.data!);
                },
              );
            },
          );
        }
        return _errorRoute();
      
      case supplierForm:
        // SupplierFormScreen dapat menerima parameter opsional
        return MaterialPageRoute(
          builder: (_) => const SupplierFormScreen()
        );
      
      case salesReport:
        return MaterialPageRoute(builder: (_) => const SalesReport());
      
      case inventoryReport:
        return MaterialPageRoute(builder: (_) => const InventoryReportScreen());
      
      case financialReport:
        return MaterialPageRoute(builder: (_) => const FinancialReport());
      
      case businessProfile:
        return MaterialPageRoute(builder: (_) => const BusinessProfileScreen());
      
      case userManagement:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());
      
      case appSettings:
        return MaterialPageRoute(builder: (_) => const AppSettingsScreen());
      
      default:
        return _errorRoute();
    }
  }
  
  // Helper method untuk mendapatkan customer berdasarkan ID
  static Future<Customer?> _getCustomerById(int id) async {
    final dbService = DatabaseService();
    final customers = await dbService.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (customers.isEmpty) {
      return null;
    }
    
    return Customer.fromMap(customers.first);
  }
  
  // Helper method untuk mendapatkan supplier berdasarkan ID
  static Future<Supplier?> _getSupplierById(int id) async {
    final dbService = DatabaseService();
    final suppliers = await dbService.query(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (suppliers.isEmpty) {
      return null;
    }
    
    return Supplier.fromMap(suppliers.first);
  }
  
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Route tidak ditemukan!'),
        ),
      ),
    );
  }
}