// lib/utils/helpers.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Utility class for various helper functions
class Helpers {
  /// Initialize app-wide utilities
  static Future<void> initialize() async {
    // Initialize date formatting for Indonesian locale
    await initializeDateFormatting('id_ID');
  }

  /// Get formatted current date
  static String getCurrentDate({String format = 'yyyy-MM-dd'}) {
    return DateFormat(format).format(DateTime.now());
  }

  /// Get current date time as DateTime object
  static DateTime getCurrentDateTime() {
    return DateTime.now();
  }

  /// Convert SQLite datetime string to DateTime object
  static DateTime? parseSqliteDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Generate invoice number
  static String generateInvoiceNumber(String prefix, int id, DateTime date) {
    final dateStr = DateFormat('yyMMdd').format(date);
    final paddedId = id.toString().padLeft(4, '0');
    return '$prefix$dateStr$paddedId';
  }

  /// Calculate discount amount based on discount type and value
  static double calculateDiscount(double amount, String discountType, double discountValue) {
    if (discountType == 'percentage') {
      return amount * (discountValue / 100);
    } else { // fixed
      return discountValue;
    }
  }

  /// Calculate tax amount
  static double calculateTax(double amount, double taxRate) {
    return amount * (taxRate / 100);
  }

  /// Store data in shared preferences
  static Future<bool> saveToPrefs(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (value is String) {
      return await prefs.setString(key, value);
    } else if (value is int) {
      return await prefs.setInt(key, value);
    } else if (value is double) {
      return await prefs.setDouble(key, value);
    } else if (value is bool) {
      return await prefs.setBool(key, value);
    } else if (value is List<String>) {
      return await prefs.setStringList(key, value);
    } else {
      // For complex objects, convert to JSON string
      return await prefs.setString(key, jsonEncode(value));
    }
  }

  /// Get data from shared preferences
  static Future<dynamic> getFromPrefs(String key, Type type) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (type == String) {
      return prefs.getString(key);
    } else if (type == int) {
      return prefs.getInt(key);
    } else if (type == double) {
      return prefs.getDouble(key);
    } else if (type == bool) {
      return prefs.getBool(key);
    } else if (type == List<String>) {
      return prefs.getStringList(key);
    } else {
      // For complex objects, get JSON string and decode
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString);
      }
      return null;
    }
  }

  /// Parse SQLite boolean (0/1) to Dart boolean
  static bool parseSqliteBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }
}