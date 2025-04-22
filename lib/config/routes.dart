// config/routes.dart
import 'package:flutter/material.dart';

// Auth Screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';

// Main Screens
import '../screens/dashboard/dashboard_screen.dart';

// Transaction Screens
import '../screens/transactions/pos_screen.dart';
import '../screens/transactions/purchasing_screen.dart';
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
  static const String expenseReport = '/reports/expenses';
  
  // Settings routes
  static const String businessProfile = '/settings/business';
  static const String userManagement = '/settings/users';
  static const String appSettings = '/settings/app';
  
  // Expense routes
  static const String expenses = '/expenses';
  static const String expenseDetail = '/expenses/detail';
  static const String expenseForm = '/expenses/form';

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
        return MaterialPageRoute(builder: (_) => const TransactionHistoryScreen());
      
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
          builder: (_) => ProductFormScreen(productId: productId)
        );
      
      case categories:
        return MaterialPageRoute(builder: (_) => const CategoryListScreen());
      
      case stockOpname:
        return MaterialPageRoute(builder: (_) => const StockOpnameScreen());
        
      case inventoryMovements:
        return MaterialPageRoute(builder: (_) => const InventoryMovementScreen());
      
      case customers:
        return MaterialPageRoute(builder: (_) => const CustomerListScreen());
      
      case customerDetail:
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(customerId: args)
          );
        }
        return _errorRoute();
      
      case customerForm:
        int? customerId;
        if (args != null && args is int) {
          customerId = args;
        }
        return MaterialPageRoute(
          builder: (_) => CustomerFormScreen(customerId: customerId)
        );
      
      case suppliers:
        return MaterialPageRoute(builder: (_) => const SupplierListScreen());
      
      case supplierDetail:
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => SupplierDetailScreen(supplierId: args)
          );
        }
        return _errorRoute();
      
      case supplierForm:
        int? supplierId;
        if (args != null && args is int) {
          supplierId = args;
        }
        return MaterialPageRoute(
          builder: (_) => SupplierFormScreen(supplierId: supplierId)
        );
      
      case salesReport:
        return MaterialPageRoute(builder: (_) => const SalesReportScreen());
      
      case inventoryReport:
        return MaterialPageRoute(builder: (_) => const InventoryReportScreen());
      
      case financialReport:
        return MaterialPageRoute(builder: (_) => const FinancialReportScreen());
        
      case expenseReport:
        return MaterialPageRoute(builder: (_) => const ExpenseReportScreen());
      
      case businessProfile:
        return MaterialPageRoute(builder: (_) => const BusinessProfileScreen());
      
      case userManagement:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());
      
      case appSettings:
        return MaterialPageRoute(builder: (_) => const AppSettingsScreen());
        
      case expenses:
        return MaterialPageRoute(builder: (_) => const ExpenseListScreen());
        
      case expenseDetail:
        if (args is int) {
          return MaterialPageRoute(
            builder: (_) => ExpenseDetailScreen(expenseId: args)
          );
        }
        return _errorRoute();
        
      case expenseForm:
        int? expenseId;
        if (args != null && args is int) {
          expenseId = args;
        }
        return MaterialPageRoute(
          builder: (_) => ExpenseFormScreen(expenseId: expenseId)
        );
      
      default:
        return _errorRoute();
    }
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