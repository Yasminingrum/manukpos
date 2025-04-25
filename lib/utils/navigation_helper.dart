// utils/navigation_helper.dart
import 'package:flutter/material.dart';

class NavigationHelper {
  static void goBack(BuildContext context, [dynamic result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }
  
  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }
  
  static Future<T?> navigateReplace<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, dynamic>(context, routeName, arguments: arguments);
  }
  
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      '/dashboard', 
      (route) => false
    );
  }
  
  // Helper untuk menampilkan dialog konfirmasi sebelum kembali
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
}