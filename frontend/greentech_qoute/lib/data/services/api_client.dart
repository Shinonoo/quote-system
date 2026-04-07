import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditionally import dart:io for non-web platforms
import 'api_client_stub.dart'
    if (dart.library.io) 'api_client_io.dart';

/// API Client for making HTTP requests to the backend
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Dio? _dio;
  String? _authToken;

  // API Base URL - Change this to your backend URL
  // For Android emulator use: http://10.0.2.2:3000
  // For iOS simulator use: http://localhost:3000
  // For physical device use: http://YOUR_COMPUTER_IP:3000
  static String get baseUrl {
    // Use appropriate URL based on platform
    if (kIsWeb) {
      return 'http://localhost:3000/api/';
    }
    return getPlatformBaseUrl();
  }

  Future<void> initialize() async {
    // Already initialized
    if (_dio != null) return;
    
    final url = baseUrl;
    debugPrint('🔧 API Client initializing with baseUrl: $url');
    
    final dio = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptor for auth token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          debugPrint('🌐 REQUEST: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ RESPONSE: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ ERROR: ${error.response?.statusCode} ${error.message}');
          return handler.next(error);
        },
      ),
    );

    _dio = dio;

    // Load saved token
    await _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  Future<void> setToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  bool get isAuthenticated => _authToken != null;

  // HTTP Methods
  Dio get _client {
    if (_dio == null) {
      throw Exception('ApiClient not initialized. Call initialize() first.');
    }
    return _dio!;
  }
  
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final fullUrl = '${_client.options.baseUrl}/$path';
    debugPrint('🌐 GET $fullUrl');
    return await _client.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    final fullUrl = '${_client.options.baseUrl}/$path';
    debugPrint('🌐 POST $fullUrl');
    return await _client.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _client.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _client.delete(path);
  }
}
