import 'package:dio/dio.dart';
import 'api_client.dart';

/// Service for handling quote API operations
class QuoteApiService {
  static final QuoteApiService _instance = QuoteApiService._internal();
  factory QuoteApiService() => _instance;
  QuoteApiService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Get all quotations
  Future<Map<String, dynamic>> getAllQuotes() async {
    try {
      final response = await _apiClient.get('quotes');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': _extractErrorMessage(e),
      };
    }
  }

  /// Get a single quote by quote number
  Future<Map<String, dynamic>> getQuoteByNo(String quoteNo) async {
    try {
      final response = await _apiClient.get('quotes/$quoteNo');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } catch (e) {
      // Try by reference_no if quote_no fails
      try {
        final response = await _apiClient.get('quotes/ref/$quoteNo');
        return {
          'success': true,
          'data': response.data['data'],
        };
      } catch (_) {
        return {
          'success': false,
          'message': _extractErrorMessage(e),
        };
      }
    }
  }

  /// Create a new quotation
  Future<Map<String, dynamic>> createQuote({
    required String companyName,
    required String companyLocation,
    required String attentionName,
    required String attentionPosition,
    required String customerProject,
    required String projectLocation,
    required int createdBy,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _apiClient.post(
        'quotes/create',
        data: {
          'company_name': companyName,
          'company_location': companyLocation,
          'attention_name': attentionName,
          'attention_position': attentionPosition,
          'customer_project': customerProject,
          'project_location': projectLocation,
          'created_by': createdBy,
          'items': items,
        },
      );

      return {
        'success': true,
        'quoteNo': response.data['quote_no'],
        'referenceNo': response.data['reference_no'],
        'grandTotal': response.data['grand_total'],
        'message': 'Quote created successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': _extractErrorMessage(e),
      };
    }
  }

  /// Get all equipment types
  Future<Map<String, dynamic>> getEquipmentTypes() async {
    try {
      final response = await _apiClient.get('quotes/equipment');
      return {
        'success': true,
        'data': response.data['data'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': _extractErrorMessage(e),
      };
    }
  }

  /// Update quote status
  Future<Map<String, dynamic>> updateStatus(String quoteNo, String status) async {
    try {
      final response = await _apiClient.put(
        'quotes/$quoteNo/status',
        data: {'status': status},
      );
      return {
        'success': true,
        'data': response.data['data'],
        'message': response.data['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': _extractErrorMessage(e),
      };
    }
  }

  /// Test database connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await _apiClient.get('test');
      return {
        'success': true,
        'message': response.data['message'],
        'result': response.data['result'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': _extractErrorMessage(e),
      };
    }
  }

  String _extractErrorMessage(dynamic error) {
    // Handle DioException (Dio 5.x+)
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please check your internet connection.';
        case DioExceptionType.unknown:
          final errStr = error.error?.toString() ?? '';
          if (errStr.contains('SocketException')) {
            return 'Cannot connect to server. Please check:\n'
                   '1. Backend server is running\n'
                   '2. Device and server are on the same network\n'
                   '3. IP address is correct';
          }
          break;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final data = error.response?.data;
          if (statusCode == 404) {
            return 'Resource not found';
          } else if (statusCode == 401) {
            return 'Unauthorized. Please login again.';
          } else if (statusCode == 403) {
            return 'Access denied';
          } else if (statusCode == 422 && data != null) {
            if (data is Map && data['message'] != null) {
              return 'Validation error: ${data['message']}';
            }
            if (data is Map && data['errors'] != null) {
              return 'Validation error: ${data['errors']}';
            }
            return 'Invalid data sent to server';
          } else if (statusCode != null && statusCode >= 500) {
            return 'Server error ($statusCode): ${data?['message'] ?? 'Please try again later.'}';
          }
          break;
        default:
          break;
      }
    }
    
    // Fallback to string parsing
    final errorStr = error.toString();
    if (errorStr.contains('404')) {
      return 'Resource not found';
    } else if (errorStr.contains('401')) {
      return 'Unauthorized. Please login again.';
    } else if (errorStr.contains('403')) {
      return 'Access denied';
    } else if (errorStr.contains('500')) {
      return 'Server error. Please try again later.';
    } else if (errorStr.contains('SocketException') || errorStr.contains('Connection refused')) {
      return 'Cannot connect to server. Please check your backend is running.';
    }
    return 'An error occurred: ${errorStr.length > 100 ? errorStr.substring(0, 100) : errorStr}';
  }
}
