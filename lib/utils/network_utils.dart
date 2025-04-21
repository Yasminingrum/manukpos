// lib/utils/network_utils.dart
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Utility class for network operations and connectivity
class NetworkUtils {
  /// Check if the device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      // Additional check to verify actual internet connection
      final response = await http.get(Uri.parse('https://google.com'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get base API URL from config or preferences
  static Future<String> getBaseUrl() async {
    // TODO: Implement getting the base URL from shared preferences or config
    return 'https://api.manuk-pos.com/api/v1';
  }

  /// Add headers to request
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  /// Perform a GET request
  static Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? headers, String? token}) async {
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/$endpoint');
      
      final response = await http.get(
        url,
        headers: headers ?? getHeaders(token: token),
      );
      
      return _processResponse(response);
    } on SocketException {
      throw 'No Internet connection';
    } catch (e) {
      throw 'Error occurred: $e';
    }
  }

  /// Perform a POST request
  static Future<Map<String, dynamic>> post(
    String endpoint, 
    dynamic body, 
    {Map<String, String>? headers, String? token}
  ) async {
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/$endpoint');
      
      final response = await http.post(
        url,
        body: jsonEncode(body),
        headers: headers ?? getHeaders(token: token),
      );
      
      return _processResponse(response);
    } on SocketException {
      throw 'No Internet connection';
    } catch (e) {
      throw 'Error occurred: $e';
    }
  }

  /// Perform a PUT request
  static Future<Map<String, dynamic>> put(
    String endpoint, 
    dynamic body, 
    {Map<String, String>? headers, String? token}
  ) async {
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/$endpoint');
      
      final response = await http.put(
        url,
        body: jsonEncode(body),
        headers: headers ?? getHeaders(token: token),
      );
      
      return _processResponse(response);
    } on SocketException {
      throw 'No Internet connection';
    } catch (e) {
      throw 'Error occurred: $e';
    }
  }

  /// Perform a DELETE request
  static Future<Map<String, dynamic>> delete(
    String endpoint, 
    {Map<String, String>? headers, String? token}
  ) async {
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/$endpoint');
      
      final response = await http.delete(
        url,
        headers: headers ?? getHeaders(token: token),
      );
      
      return _processResponse(response);
    } on SocketException {
      throw 'No Internet connection';
    } catch (e) {
      throw 'Error occurred: $e';
    }
  }

  /// Process HTTP response
  static Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw 'Unauthorized';
    } else if (response.statusCode == 404) {
      throw 'Not found';
    } else {
      throw 'Error: ${response.statusCode} - ${response.reasonPhrase}';
    }
  }
}
