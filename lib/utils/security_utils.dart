// lib/utils/security_utils.dart
import 'dart:convert';
// Import untuk Uint8List
import 'dart:math'; // Import untuk Random
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart'; // Import untuk debugPrint

/// Utility class for security operations
class SecurityUtils {
  static final _secureStorage = const FlutterSecureStorage();
  static const _encryptionKey = 'MANUK_POS_ENCRYPTION_KEY';
  
  /// Generate a secure hash for passwords
  static String hashPassword(String password, {String salt = ''}) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Encrypt sensitive data
  static Future<String> encryptData(String data) async {
    final key = await _getEncryptionKey();
    final keyBytes = utf8.encode(key);
    final paddedKeyBytes = keyBytes.length < 32 
        ? keyBytes + List<int>.filled(32 - keyBytes.length, 0) 
        : keyBytes.sublist(0, 32);
    
    final encryptKey = encrypt.Key(Uint8List.fromList(paddedKeyBytes));
    final iv = encrypt.IV.fromLength(16);
    
    final encrypter = encrypt.Encrypter(encrypt.AES(encryptKey));
    final encrypted = encrypter.encrypt(data, iv: iv);
    
    return encrypted.base64;
  }
  
  /// Decrypt sensitive data
  static Future<String> decryptData(String encryptedData) async {
    try {
      final key = await _getEncryptionKey();
      final keyBytes = utf8.encode(key);
      final paddedKeyBytes = keyBytes.length < 32 
          ? keyBytes + List<int>.filled(32 - keyBytes.length, 0) 
          : keyBytes.sublist(0, 32);
      
      final encryptKey = encrypt.Key(Uint8List.fromList(paddedKeyBytes));
      final iv = encrypt.IV.fromLength(16);
      
      final encrypter = encrypt.Encrypter(encrypt.AES(encryptKey));
      final decrypted = encrypter.decrypt64(encryptedData, iv: iv);
      
      return decrypted;
    } catch (e) {
      debugPrint('Error decrypting data: $e');
      return '';
    }
  }
  
  /// Save sensitive data securely
  static Future<void> saveSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  /// Retrieve sensitive data securely
  static Future<String?> getSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  /// Delete sensitive data
  static Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  /// Clear all secure storage
  static Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }
  
  /// Get encryption key from secure storage or generate a new one
  static Future<String> _getEncryptionKey() async {
    String? key = await _secureStorage.read(key: _encryptionKey);
    
    if (key == null) {
      key = _generateRandomKey();
      await _secureStorage.write(key: _encryptionKey, value: key);
    }
    
    return key;
  }
  
  /// Generate a random encryption key
  static String _generateRandomKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
}