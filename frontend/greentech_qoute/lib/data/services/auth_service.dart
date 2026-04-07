import 'api_client.dart';

/// Service for handling authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Login user and get JWT token
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = response.data;
      
      if (data['token'] != null) {
        await _apiClient.setToken(data['token']);
      }

      return {
        'success': true,
        'token': data['token'],
        'user': data['user'],
        'message': data['message'],
      };
    } catch (e) {
      String message = 'Login failed';
      if (e is Exception) {
        final errorMsg = e.toString();
        if (errorMsg.contains('401')) {
          message = 'Invalid username or password';
        } else if (errorMsg.contains('connection')) {
          message = 'Cannot connect to server. Please check your internet connection.';
        }
      }
      return {
        'success': false,
        'message': message,
      };
    }
  }

  /// Register a new user (admin use only)
  Future<Map<String, dynamic>> register(String username, String password) async {
    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
        },
      );

      return {
        'success': true,
        'message': response.data['message'],
        'userId': response.data['userId'],
      };
    } catch (e) {
      String message = 'Registration failed';
      if (e.toString().contains('400')) {
        message = 'Username already exists';
      }
      return {
        'success': false,
        'message': message,
      };
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _apiClient.clearToken();
  }

  /// Check if user is logged in
  bool get isLoggedIn => _apiClient.isAuthenticated;
  
  /// Get current user ID (stored after login)
  int? get currentUserId {
    // The user ID is extracted from JWT token on backend
    // For now, return 1 as default since backend gets it from token
    return 1;
  }
}
