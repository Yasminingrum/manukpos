// lib/utils/locale_utils.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for locale and internationalization operations
class LocaleUtils {
  static const String _localePrefsKey = 'app_locale';
  static const Locale defaultLocale = Locale('id', 'ID');
  
  /// Initialize localization
  static Future<void> initialize() async {
    await initializeDateFormatting('id_ID');
  }
  
  /// Get the current locale
  static Future<Locale> getCurrentLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeString = prefs.getString(_localePrefsKey);
    
    if (localeString != null) {
      final parts = localeString.split('_');
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      }
    }
    
    return defaultLocale;
  }
  
  /// Set the current locale
  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefsKey, '${locale.languageCode}_${locale.countryCode}');
  }
  
  /// Get a localized string
  static String getLocalizedString(Map<String, String> translations, String key, [String defaultValue = '']) {
    return translations[key] ?? defaultValue;
  }
  
  /// Format currency for current locale
  static String formatCurrency(num amount, [String? currencyCode]) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: currencyCode ?? 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }
  
  /// Format date for current locale
  static String formatDate(DateTime date, [String? pattern]) {
    return DateFormat(pattern ?? 'dd MMMM yyyy', 'id_ID').format(date);
  }
  
  /// Format number for current locale
  static String formatNumber(num number, [int? decimalDigits]) {
    return NumberFormat.decimalPattern('id_ID').format(number);
  }
  
  /// Translate day name to Indonesian
  static String getDayName(int weekday, {bool abbreviated = false}) {
    final days = abbreviated 
        ? ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
        : ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    
    return days[weekday - 1];
  }
  
  /// Translate month name to Indonesian
  static String getMonthName(int month, {bool abbreviated = false}) {
    final months = abbreviated
        ? ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des']
        : ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    
    return months[month - 1];
  }
  
  /// Get supported locales
  static List<Locale> getSupportedLocales() {
    return [
      const Locale('id', 'ID'),
      const Locale('en', 'US'),
    ];
  }
}