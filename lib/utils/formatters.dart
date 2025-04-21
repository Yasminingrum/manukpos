// lib/utils/formatters.dart
import 'package:intl/intl.dart';

/// Utility class for formatting various data types
class Formatters {
  /// Format currency value for Indonesian Rupiah
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format date to Indonesian format
  static String formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  /// Format datetime to Indonesian format with time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  /// Format date for API requests (ISO format)
  static String formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format short date (dd/MM/yyyy)
  static String formatShortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format time only
  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Format a number with thousand separator
  static String formatNumber(num number) {
    final formatter = NumberFormat('#,###');
    return formatter.format(number);
  }

  /// Format a quantity with decimal places
  static String formatQuantity(num quantity, {int decimalDigits = 2}) {
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }
    final formatter = NumberFormat('#,##0.${'0' * decimalDigits}');
    return formatter.format(quantity);
  }

  /// Format phone number in Indonesian format
  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';
    
    // Remove all non-numeric characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Check if starts with '0' and replace with '+62'
    if (cleaned.startsWith('0')) {
      cleaned = '+62${cleaned.substring(1)}';
    }
    
    // If it doesn't have country code, add it
    if (!cleaned.startsWith('+')) {
      cleaned = '+62$cleaned';
    }
    
    return cleaned;
  }
}