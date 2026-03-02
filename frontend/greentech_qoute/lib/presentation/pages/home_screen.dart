import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/remote_data_source.dart';  // Fixed path
import '../../core/errors/api_exception.dart';
import '../../utils/error_handler.dart';
import 'create_quote_screen.dart';
import 'receipt_screen.dart';
import '../../core/errors/api_exception.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _quotations = [];
  bool _isLoading = true;
  String _username = "Admin";

  final Color fernGreen = Color(0xFF4F7942);
  final Color fernGreenLight = Color(0xFF6A9A5C);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchQuotations();
  }

  // ─── Load User ────────────────────────────────────────────────────────────

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? "Admin";
      });
    }
  }

  // ─── Fetch Quotations ─────────────────────────────────────────────────────

  Future<void> _fetchQuotations() async {
    try {
      final response = await _apiClient.dio.get('/quotes');
      if (mounted) {
        setState(() {
          _quotations = response.data['data'] ?? response.data;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
          debugPrint('STATUS: ${e.response?.statusCode}');  // ← add this
    debugPrint('ERROR TYPE: ${e.error.runtimeType}'); // ← add this
    debugPrint('ERROR: ${e.error}');                  // ← add this
      final error = e.error is ApiException
          ? e.error as ApiException
          : ApiException('Failed to load quotations.');
      if (mounted) {
        setState(() => _isLoading = false);
        handleError(context, error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        handleError(context, ApiException('Unexpected error loading quotations.'));
      }
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    // Reuse the centralized clearSession from ApiClient
    // await ApiClient.clearSession(context);
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: _buildBody(),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 220.0,
      floating: false,
      pinned: true,
      backgroundColor: fernGreen,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [fernGreen, fernGreenLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative icon
            Positioned(
              right: -30, top: -20,
              child: Icon(Icons.description, size: 150, color: Colors.white.withOpacity(0.1)),
            ),
            // Welcome text
            Positioned(
              left: 20, bottom: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome Back,", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 5),
                  Text(_username, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${_quotations.length} Active Quotations",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: Colors.white),
          tooltip: 'Logout',
          onPressed: _logout,
        ),
      ],
    );
  }

  // ─── Body Sliver ──────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: fernGreen)),
      );
    }

    if (_quotations.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildQuoteCard(_quotations[index]),
        childCount: _quotations.length,
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
          SizedBox(height: 15),
          Text("No quotations yet", style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text("Tap + NEW QUOTE to get started", style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ─── Quote Card ───────────────────────────────────────────────────────────

  Widget _buildQuoteCard(Map<String, dynamic> quote) {
    final dateStr = _parseDate(quote['created_at']);
    final clientName = quote['company_name'] ?? quote['customer_name'] ?? 'Unknown Client';
    final grandTotal = _formatCurrency(quote['grand_total']);

    return GestureDetector(
      onTap: () => _navigateToReceipt(quote['quote_no']),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Left icon box
              Container(
                height: 50, width: 50,
                decoration: BoxDecoration(
                  color: fernGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long, color: fernGreen),
              ),
              SizedBox(width: 16),

              // Main text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote['customer_project'] ?? 'Unknown Project',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${quote['reference_no']} • $dateStr",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      clientName,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Right price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "PHP $grandTotal",
                    style: TextStyle(fontWeight: FontWeight.w900, color: fernGreen, fontSize: 15),
                  ),
                  SizedBox(height: 5),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade300),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FAB ─────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreateQuoteScreen()),
      ),
      backgroundColor: fernGreen,
      icon: Icon(Icons.add, color: Colors.white),
      label: Text("NEW QUOTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      elevation: 4,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _navigateToReceipt(dynamic quoteNo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReceiptScreen(quoteNo: quoteNo)),
    );
  }

  /// Safely parses a date string, returns 'N/A' on failure
  String _parseDate(dynamic raw) {
    try {
      return raw.toString().substring(0, 10);
    } catch (_) {
      return 'N/A';
    }
  }

  /// Formats grand_total safely — handles null and non-numeric values
  String _formatCurrency(dynamic value) {
    if (value == null) return '0.00';
    try {
      return double.parse(value.toString()).toStringAsFixed(2);
    } catch (_) {
      return value.toString();
    }
  }
}
