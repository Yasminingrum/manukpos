// lib/utils/number_utils.dart
import 'package:intl/intl.dart';
import 'dart:math';

/// Utility class for number operations
class NumberUtils {
  /// Format number with thousand separator
  static String formatNumber(num number, {int decimal = 0}) {
    return NumberFormat.decimalPattern('id_ID').format(number);
  }

  /// Format currency in Indonesian Rupiah
  static String formatCurrency(num number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  /// Format percentage
  static String formatPercentage(num number, {int decimal = 2}) {
    return NumberFormat.percentPattern('id_ID')
      .format(number / 100);
  }

  /// Parse currency string to number
  static double? parseCurrency(String currencyString) {
    try {
      // Remove all non-numeric characters except decimal point
      final numericString = currencyString.replaceAll(RegExp(r'[^0-9,.]'), '');
      // Replace comma with dot if used as decimal separator
      final normalizedString = numericString.replaceAll(',', '.');
      return double.parse(normalizedString);
    } catch (e) {
      return null;
    }
  }

  /// Round to specified decimal places
  static double roundToDecimal(double number, int decimal) {
    final mod = pow(10.0, decimal);
    return (number * mod).round() / mod;
  }

  /// Calculate percentage
  static double calculatePercentage(num value, num total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  /// Calculate discount
  static double calculateDiscount(double price, double discountPercentage) {
    return price * (discountPercentage / 100);
  }

  /// Apply discount to price
  static double applyDiscount(double price, double discountPercentage) {
    return price - calculateDiscount(price, discountPercentage);
  }

  /// Calculate tax
  static double calculateTax(double amount, double taxRate) {
    return amount * (taxRate / 100);
  }

  /// Generate random number within range
  static int generateRandomNumber(int min, int max) {
    final random = Random();
    return min + random.nextInt(max - min + 1);
  }

  /// Generate reference number with prefix
  static String generateReferenceNumber(String prefix, [int length = 8]) {
    final random = Random();
    final numbers = List.generate(length, (_) => random.nextInt(10)).join();
    return '$prefix$numbers';
  }

  /// Check if string is numeric
  static bool isNumeric(String? str) {
    if (str == null) return false;
    return double.tryParse(str) != null;
  }

  /// Convert number to words in Indonesian
  static String numberToWords(int number) {
    if (number == 0) return 'nol';
    
    const ones = ['', 'satu', 'dua', 'tiga', 'empat', 'lima', 'enam', 'tujuh', 'delapan', 'sembilan', 'sepuluh',
                  'sebelas', 'dua belas', 'tiga belas', 'empat belas', 'lima belas', 'enam belas', 'tujuh belas', 'delapan belas', 'sembilan belas'];
    const tens = ['', '', 'dua puluh', 'tiga puluh', 'empat puluh', 'lima puluh', 'enam puluh', 'tujuh puluh', 'delapan puluh', 'sembilan puluh'];
    
    String words = '';
    
    if (number < 0) {
      words += 'minus ';
      number = number.abs();
    }
    
    if (number < 20) {
      words += ones[number];
    } else if (number < 100) {
      words += tens[number ~/ 10] + (number % 10 != 0 ? ' ${ones[number % 10]}' : '');
    } else if (number < 1000) {
      words += (number ~/ 100 == 1 ? 'seratus' : '${ones[number ~/ 100]} ratus') + (number % 100 != 0 ? ' ${numberToWords(number % 100)}' : '');
    } else if (number < 1000000) {
      words += (number ~/ 1000 == 1 ? 'seribu' : '${numberToWords(number ~/ 1000)} ribu') + (number % 1000 != 0 ? ' ${numberToWords(number % 1000)}' : '');
    } else if (number < 1000000000) {
      words += '${numberToWords(number ~/ 1000000)} juta${number % 1000000 != 0 ? ' ${numberToWords(number % 1000000)}' : ''}';
    } else {
      words += '${numberToWords(number ~/ 1000000000)} milyar${number % 1000000000 != 0 ? ' ${numberToWords(number % 1000000000)}' : ''}';
    }
    
    return words;
  }
}