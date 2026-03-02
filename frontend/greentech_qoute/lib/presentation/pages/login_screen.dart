import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/remote_data_source.dart';  // Fixed path
import '../../core/errors/api_exception.dart';
import '../../utils/error_handler.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final Color fernGreen = Color(0xFF4F7942);
  final Color fernGreenLight = Color(0xFF6A9A5C);

  // ─── Dispose ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  Future<void> _login() async {
    // Use the Form's built-in validation instead of manual isEmpty checks
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
      });

      await _saveSession(response.data);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      }
    } on DioException catch (e) {
      // Use the server's error message if available, else fall back to typed exception
      final serverMsg = e.response?.data?['error'] ?? e.response?.data?['message'];
      final error = serverMsg != null
          ? ApiException(serverMsg, statusCode: e.response?.statusCode)
          : (e.error is ApiException ? e.error as ApiException : ApiException('Login failed. Please check your credentials.'));

      if (mounted) handleError(context, error);
    } catch (e) {
      if (mounted) handleError(context, ApiException('Unexpected error. Please try again.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Saves JWT token, user_id, and username to SharedPreferences
  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', data['token']);

    final user = data['user'];
    if (user != null) {
      if (user['id'] != null) await prefs.setInt('user_id', user['id']);
      if (user['username'] != null) await prefs.setString('username', user['username']);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeader(context),
              _buildFormCard(),
              SizedBox(height: 10),
              Text("© 2026 GreenTech HVAC", style: TextStyle(color: Colors.grey, fontSize: 12)),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return ClipPath(
      clipper: LoginHeaderClipper(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [fernGreen, fernGreenLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo circle
              Container(
                height: 100, width: 100,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/greentech_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.ac_unit, size: 50, color: fernGreen),
                ),
              ),
              SizedBox(height: 15),
              Text(
                "GreenTech",
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
              ),
              Text(
                "Quotation Management System",
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), letterSpacing: 0.5),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Form Card ────────────────────────────────────────────────────────────

  Widget _buildFormCard() {
    return Transform.translate(
      offset: Offset(0, -50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Card(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome Back", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                SizedBox(height: 8),
                Text("Sign in to continue", style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                SizedBox(height: 30),

                // ── Username Field ──
                _buildInputField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.person_outline,
                  validator: (v) => v!.trim().isEmpty ? 'Username is required' : null,
                ),
                SizedBox(height: 20),

                // ── Password Field ──
                _buildInputField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  validator: (v) => v!.trim().isEmpty ? 'Password is required' : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                SizedBox(height: 40),

                // ── Login Button ──
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fernGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                        : Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Reusable Input Field ─────────────────────────────────────────────────

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: fernGreen),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: fernGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}

// ─── Header Clipper ───────────────────────────────────────────────────────────

class LoginHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
