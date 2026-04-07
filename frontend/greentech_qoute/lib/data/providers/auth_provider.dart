import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _user;
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isInitialized => _isInitialized;

  /// Initialize auth state (call this at app startup)
  Future<void> initialize() async {
    try {
      await ApiClient().initialize();
      
      // Check if we have a saved token
      if (AuthService().isLoggedIn) {
        // Token exists, user might be logged in
        // In a real app, you might want to validate the token here
        _user = null; // Will need to re-login
      }
    } catch (e) {
      // Ignore errors during initialization
      // Auth initialization error
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Login user
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(username, password);

    _isLoading = false;

    if (result['success'] == true) {
      _user = result['user'] as Map<String, dynamic>?;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result['message'] as String?;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
