// lib/utils/navigation_utils.dart
import 'package:flutter/material.dart';
import '../app.dart';

/// Helper class untuk navigasi yang lebih mudah
class NavigationUtils {
  /// Kembali ke halaman sebelumnya
  static void goBack(BuildContext context, [dynamic result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  /// Navigasi ke route tertentu
  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  /// Navigasi dengan replacement (mengganti screen saat ini)
  static Future<T?> navigateReplace<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, dynamic>(context, routeName, arguments: arguments);
  }

  /// Navigasi ke home/dashboard (menghapus semua stack)
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      '/dashboard', 
      (route) => false
    );
  }

  /// Dialog konfirmasi sebelum kembali
  static Future<bool> confirmExit(BuildContext context, {String? message}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(message ?? 'Apakah Anda yakin ingin kembali?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Navigasi menggunakan global navigator key
  static void goBackGlobal([dynamic result]) {
    final context = GlobalNavigatorKey.key.currentContext;
    if (context != null && Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }
}

/// Extension pada BuildContext untuk kemudahan navigasi
extension NavigationExtensions on BuildContext {
  /// Kembali ke halaman sebelumnya
  void goBack([dynamic result]) {
    if (Navigator.canPop(this)) {
      Navigator.pop(this, result);
    }
  }
  
  /// Navigasi ke route tertentu
  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(this, routeName, arguments: arguments);
  }
  
  /// Navigasi dengan replacement
  Future<T?> navigateReplace<T>(String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, dynamic>(this, routeName, arguments: arguments);
  }
  
  /// Navigasi ke home/dashboard
  void navigateToHome() {
    Navigator.pushNamedAndRemoveUntil(
      this, 
      '/dashboard', 
      (route) => false
    );
  }
  
  /// Dialog konfirmasi sebelum kembali
  Future<bool> confirmGoBack({String? message}) async {
    final result = await showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text(message ?? 'Apakah Anda yakin ingin kembali?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}