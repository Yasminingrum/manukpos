// lib/utils/ui_utils.dart
import 'package:flutter/material.dart';

/// Utility class for UI related helpers
class UiUtils {
  /// Show a snackbar message
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  /// Show a loading dialog
  static void showLoadingDialog(BuildContext context, {String message = 'Mohon tunggu...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Hide the current dialog
  static void hideDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Show a confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, 
    String title, 
    String message, 
    {String confirmText = 'Ya', String cancelText = 'Batal'}
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Show a custom bottom sheet
  static Future<T?> showCustomBottomSheet<T>(
    BuildContext context, 
    Widget child, 
    {double initialChildSize = 0.5, double maxChildSize = 0.9}
  ) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        maxChildSize: maxChildSize,
        minChildSize: 0.25,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: scrollController,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Add spacing between widgets
  static Widget addVerticalSpace(double height) {
    return SizedBox(height: height);
  }

  /// Add horizontal spacing between widgets
  static Widget addHorizontalSpace(double width) {
    return SizedBox(width: width);
  }

  /// Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = getScreenWidth(context);
    
    if (screenWidth > 600) {
      return baseFontSize * 1.2; // Tablet
    } else {
      return baseFontSize; // Phone
    }
  }
}