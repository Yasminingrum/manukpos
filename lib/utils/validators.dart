// lib/utils/validators.dart
/// Utility class for validating user inputs
class Validators {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    
    return null;
  }

  /// Validate phone number format
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon tidak boleh kosong';
    }
    
    final phoneRegex = RegExp(r'^(\+62|62|0)[0-9]{9,13}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Format nomor telepon tidak valid';
    }
    
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  /// Validate numeric input
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName harus berupa angka';
    }
    
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    
    if (value.length < minLength) {
      return '$fieldName minimal $minLength karakter';
    }
    
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    
    return null;
  }

  /// Validate two passwords match
  static String? validatePasswordMatch(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    
    if (password != confirmPassword) {
      return 'Password tidak sama';
    }
    
    return null;
  }

  /// Validate price input
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Harga tidak boleh kosong';
    }
    
    final price = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    if (price == null) {
      return 'Harga tidak valid';
    }
    
    if (price < 0) {
      return 'Harga tidak boleh negatif';
    }
    
    return null;
  }

  /// Validate quantity input
  static String? validateQuantity(String? value, {bool allowFractions = false}) {
    if (value == null || value.isEmpty) {
      return 'Jumlah tidak boleh kosong';
    }
    
    final quantity = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    if (quantity == null) {
      return 'Jumlah tidak valid';
    }
    
    if (quantity <= 0) {
      return 'Jumlah harus lebih dari 0';
    }
    
    if (!allowFractions && quantity != quantity.toInt()) {
      return 'Jumlah harus berupa bilangan bulat';
    }
    
    return null;
  }
}