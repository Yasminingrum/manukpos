// lib/utils/validation_utils.dart

/// Utility class for form validations throughout the application
class ValidationUtils {
  /// Validates email addresses
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegExp.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    
    return null;
  }

  /// Validates required fields
  /// Returns null if valid, error message if invalid
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  /// Validates phone numbers (Indonesian format)
  /// Returns null if valid, error message if invalid
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon tidak boleh kosong';
    }
    
    // Remove any spaces, dashes, or parentheses
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-()]'), '');
    
    // Check for Indonesian phone format
    // Typically starts with +62 or 0, then 8-13 digits
    final phoneRegExp = RegExp(r'^(\+62|62|0)[0-9]{8,13}$');
    
    if (!phoneRegExp.hasMatch(cleanedValue)) {
      return 'Format nomor telepon tidak valid';
    }
    
    return null;
  }

  /// Validates passwords
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    
    return null;
  }

  /// Validates password confirmation
  /// Returns null if valid, error message if invalid
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    
    if (value != password) {
      return 'Password tidak sama';
    }
    
    return null;
  }

  /// Validates numeric input
  /// Returns null if valid, error message if invalid
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName harus berupa angka';
    }
    
    return null;
  }

  /// Validates positive numbers
  /// Returns null if valid, error message if invalid
  static String? validatePositiveNumber(String? value, String fieldName) {
    final numericValidation = validateNumeric(value, fieldName);
    if (numericValidation != null) {
      return numericValidation;
    }
    
    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName harus lebih besar dari 0';
    }
    
    return null;
  }

  /// Validates integer input
  /// Returns null if valid, error message if invalid
  static String? validateInteger(String? value, String fieldName) {
    final numericValidation = validateNumeric(value, fieldName);
    if (numericValidation != null) {
      return numericValidation;
    }
    
    if (int.tryParse(value!) == null) {
      return '$fieldName harus berupa bilangan bulat';
    }
    
    return null;
  }

  /// Validates dates
  /// Returns null if valid, error message if invalid
  static String? validateDate(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Format $fieldName tidak valid';
    }
  }

  /// Validates SKU format
  /// Returns null if valid, error message if invalid
  static String? validateSKU(String? value) {
    if (value == null || value.isEmpty) {
      return 'SKU tidak boleh kosong';
    }
    
    // SKU should be alphanumeric and may include hyphens or underscores
    final skuRegExp = RegExp(r'^[a-zA-Z0-9\-_]+$');
    
    if (!skuRegExp.hasMatch(value)) {
      return 'SKU hanya boleh mengandung huruf, angka, strip, dan garis bawah';
    }
    
    return null;
  }

  /// Validates URL format
  /// Returns null if valid, error message if invalid
  static String? validateURL(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'URL tidak boleh kosong' : null;
    }
    
    final urlRegExp = RegExp(
      r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlRegExp.hasMatch(value)) {
      return 'Format URL tidak valid';
    }
    
    return null;
  }

  /// Validates username format
  /// Returns null if valid, error message if invalid
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username tidak boleh kosong';
    }
    
    if (value.length < 3) {
      return 'Username minimal 3 karakter';
    }
    
    // Only allow letters, numbers, and underscores
    final usernameRegExp = RegExp(r'^[a-zA-Z0-9_]+$');
    
    if (!usernameRegExp.hasMatch(value)) {
      return 'Username hanya boleh mengandung huruf, angka, dan garis bawah';
    }
    
    return null;
  }

  /// Validates name format
  /// Returns null if valid, error message if invalid
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    
    if (value.length < 2) {
      return 'Nama terlalu pendek';
    }
    
    return null;
  }

  /// Validates postal codes (for Indonesia)
  /// Returns null if valid, error message if invalid
  static String? validatePostalCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kode pos tidak boleh kosong';
    }
    
    // Indonesian postal codes are 5 digits
    final postalCodeRegExp = RegExp(r'^\d{5}$');
    
    if (!postalCodeRegExp.hasMatch(value)) {
      return 'Kode pos harus terdiri dari 5 angka';
    }
    
    return null;
  }

  /// Validates tax ID (NPWP) format for Indonesia
  /// Returns null if valid, error message if invalid
  static String? validateTaxId(String? value, {bool required = true}) {
    if (value == null || value.isEmpty) {
      return required ? 'NPWP tidak boleh kosong' : null;
    }
    
    // Remove any dots, dashes or spaces
    final cleanedValue = value.replaceAll(RegExp(r'[.\s\-]'), '');
    
    // Indonesian NPWP consists of 15 digits
    final npwpRegExp = RegExp(r'^\d{15}$');
    
    if (!npwpRegExp.hasMatch(cleanedValue)) {
      return 'Format NPWP tidak valid';
    }
    
    return null;
  }

  /// Validates minimum length
  /// Returns null if valid, error message if invalid
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    
    if (value.length < minLength) {
      return '$fieldName minimal $minLength karakter';
    }
    
    return null;
  }

  /// Validates maximum length
  /// Returns null if valid, error message if invalid
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value == null) {
      return null;
    }
    
    if (value.length > maxLength) {
      return '$fieldName maksimal $maxLength karakter';
    }
    
    return null;
  }
}