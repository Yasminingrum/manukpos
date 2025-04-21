// lib/utils/toast_utils.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Utility class for showing toast messages
class ToastUtils {
  /// Show a toast message
  static void showToast(
    String message, {
    Toast length = Toast.LENGTH_SHORT,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Color backgroundColor = Colors.black,
    Color textColor = Colors.white,
    double fontSize = 16.0,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: length,
      gravity: gravity,
      timeInSecForIosWeb: 1,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: fontSize,
    );
  }
  
  /// Show success toast
  static void showSuccessToast(String message) {
    showToast(
      message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }
  
  /// Show error toast
  static void showErrorToast(String message) {
    showToast(
      message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      length: Toast.LENGTH_LONG,
    );
  }
  
  /// Show warning toast
  static void showWarningToast(String message) {
    showToast(
      message,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }
  
  /// Show info toast
  static void showInfoToast(String message) {
    showToast(
      message,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }
  
  /// Cancel all toasts
  static void cancelAll() {
    Fluttertoast.cancel();
  }
}