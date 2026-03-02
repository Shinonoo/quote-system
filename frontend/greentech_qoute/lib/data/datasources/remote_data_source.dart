import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/errors/api_exception.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:3000/api';
  late Dio _dio;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    debugPrint('SENDING TOKEN: $token'); // ← add this temporarily

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) {
    final statusCode = error.response?.statusCode;
    final message = error.response?.data?['message'] ?? 'An unexpected error occurred.';

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return handler.reject(error.copyWith(error: NetworkException()));
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return handler.reject(error.copyWith(error: ApiException('Request timed out.', statusCode: 408)));
    }

    switch (statusCode) {
      case 401:
      case 403:
        return handler.reject(error.copyWith(error: UnauthorizedException()));
      default:
        if (statusCode != null && statusCode >= 500) {
          return handler.reject(error.copyWith(error: ServerException(message)));
        }
        return handler.reject(error.copyWith(error: ApiException(message, statusCode: statusCode)));
    }
  }

  static Future<void> clearSession(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }
}
