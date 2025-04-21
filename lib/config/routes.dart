// config/routes.dart
import 'package:flutter/material.dart';

// Auth Screens
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';

// Main Screens
import '../screens/dashboard/dashboard_screen.dart';

// Transaction Screens

// Inventory Screens
import '../screens/inventory/product_list.dart';
import '../screens/inventory/product_detail.dart';
import '../screens/inventory/category_list.dart';
import '../screens/inventory/stock_opname.dart';

// Customer & Supplier Screens
import '../screens/customers/customer_list.dart';
import '../screens/suppliers/supplier_list.dart';

// Reports Screens

// Settings Screens
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
      
      case products:
        return MaterialPageRoute(builder: (_) => const ProductListScreen());
      
      case productDetail:
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: args as int)
        );
      
      
      case categories:
        return MaterialPageRoute(builder: (_) => const CategoryListScreen());
      
      case stockOpname:
        return MaterialPageRoute(builder: (_) => const StockOpnameScreen());
      
      case customers:
        return MaterialPageRoute(builder: (_) => const CustomerListScreen());
      
      
      
      case suppliers:
        return MaterialPageRoute(builder: (_) => const SupplierListScreen());
      
      case appSettings:
        return MaterialPageRoute(builder: (_) => const AppSettingsScreen());
      
      default:
        // If route not found, navigate to dashboard or login screen
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found!'),
            ),
          ),
        );
    }
  }
}