// services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $statusCode - $message';
}

class ApiService {
  final String baseUrl;
  final Duration timeout;

  ApiService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
  });

  // Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Double-check with a ping to a reliable server
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      return false;
    }
  }

  // Build headers for requests
  Map<String, String> _buildHeaders({String? token, bool isMultipart = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Process HTTP response
  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = response.body.isNotEmpty 
        ? jsonDecode(response.body) 
        : {'message': 'No response body'};

    if (statusCode >= 200 && statusCode < 300) {
      return responseBody;
    } else {
      final message = responseBody['message'] ?? 'Unknown error occurred';
      throw ApiException(
        message: message,
        statusCode: statusCode,
        data: responseBody is Map<String, dynamic> ? responseBody : null,
      );
    }
  }

  // Perform GET request
  Future<dynamic> get(String endpoint, {String? token, Map<String, dynamic>? queryParams}) async {
    try {
      // Check internet connection
      if (!await hasInternetConnection()) {
        throw ApiException(message: 'No internet connection');
      }

      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams?.map((key, value) => 
          MapEntry(key, value?.toString())),
      );

      final response = await http.get(
        uri,
        headers: _buildHeaders(token: token),
      ).timeout(timeout);

      return _processResponse(response);
    } on TimeoutException catch (_) {
      throw ApiException(message: 'Request timeout');
    } on SocketException catch (_) {
      throw ApiException(message: 'No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  // Perform POST request
  Future<dynamic> post(String endpoint, dynamic data, {String? token}) async {
    try {
      // Check internet connection
      if (!await hasInternetConnection()) {
        throw ApiException(message: 'No internet connection');
      }

      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        uri,
        headers: _buildHeaders(token: token),
        body: jsonEncode(data),
      ).timeout(timeout);

      return _processResponse(response);
    } on TimeoutException catch (_) {
      throw ApiException(message: 'Request timeout');
    } on SocketException catch (_) {
      throw ApiException(message: 'No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  // Perform PUT request
  Future<dynamic> put(String endpoint, dynamic data, {String? token}) async {
    try {
      // Check internet connection
      if (!await hasInternetConnection()) {
        throw ApiException(message: 'No internet connection');
      }

      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.put(
        uri,
        headers: _buildHeaders(token: token),
        body: jsonEncode(data),
      ).timeout(timeout);

      return _processResponse(response);
    } on TimeoutException catch (_) {
      throw ApiException(message: 'Request timeout');
    } on SocketException catch (_) {
      throw ApiException(message: 'No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  // Perform DELETE request
  Future<dynamic> delete(String endpoint, {String? token}) async {
    try {
      // Check internet connection
      if (!await hasInternetConnection()) {
        throw ApiException(message: 'No internet connection');
      }

      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(
        uri,
        headers: _buildHeaders(token: token),
      ).timeout(timeout);

      return _processResponse(response);
    } on TimeoutException catch (_) {
      throw ApiException(message: 'Request timeout');
    } on SocketException catch (_) {
      throw ApiException(message: 'No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  // Upload file with multipart request
  Future<dynamic> uploadFile(
    String endpoint, 
    File file, 
    String fileField, 
    {
      Map<String, dynamic>? fields,
      String? token,
    }
  ) async {
    try {
      // Check internet connection
      if (!await hasInternetConnection()) {
        throw ApiException(message: 'No internet connection');
      }

      final uri = Uri.parse('$baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          fileField,
          file.path,
          filename: file.path.split('/').last,
        ),
      );
      
      // Add additional fields
      if (fields != null) {
        fields.forEach((key, value) {
          request.fields[key] = value.toString();
        });
      }
      
      // Add headers
      request.headers.addAll(_buildHeaders(token: token, isMultipart: true));
      
      // Send request
      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _processResponse(response);
    } on TimeoutException catch (_) {
      throw ApiException(message: 'Request timeout');
    } on SocketException catch (_) {
      throw ApiException(message: 'No internet connection');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }
}