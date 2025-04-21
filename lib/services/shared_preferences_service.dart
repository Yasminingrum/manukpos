// services/shared_preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  final SharedPreferences _prefs;

  SharedPreferencesService(this._prefs);

  // Factory constructor untuk mendapatkan instance SharedPreferences
  static Future<SharedPreferencesService> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesService(prefs);
  }

  // Getter untuk mengakses instance SharedPreferences langsung
  SharedPreferences get instance => _prefs;

  // String
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  // Int
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // Double
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  // Bool
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // StringList
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  // Remove
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  // Clear
  Future<bool> clear() async {
    return await _prefs.clear();
  }

  // Check if key exists
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  // Get all keys
  Set<String> getKeys() {
    return _prefs.getKeys();
  }
}