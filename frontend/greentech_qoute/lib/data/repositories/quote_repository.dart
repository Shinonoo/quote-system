import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';
import '../services/quote_api_service.dart';
import '../services/auth_service.dart';

/// Repository for managing quotes persistence
/// Uses API when online, falls back to local storage when offline
class QuoteRepository {
  static final QuoteRepository _instance = QuoteRepository._internal();
  factory QuoteRepository() => _instance;
  QuoteRepository._internal();

  final QuoteApiService _apiService = QuoteApiService();
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Check if we should use API (when logged in) or local storage
  bool get useApi => AuthService().isLoggedIn;

  // ==================== API Methods ====================

  /// Get all quotes from API
  Future<List<dynamic>> getAllFromApi() async {
    final result = await _apiService.getAllQuotes();
    if (result['success'] == true) {
      return result['data'] as List<dynamic>;
    }
    throw Exception(result['message'] ?? 'Failed to load quotes');
  }

  /// Get a single quote from API by quote number
  Future<Map<String, dynamic>?> getByQuoteNoFromApi(String quoteNo) async {
    final result = await _apiService.getQuoteByNo(quoteNo);
    if (result['success'] == true) {
      return result['data'] as Map<String, dynamic>;
    }
    return null;
  }

  /// Create a new quote via API
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
    return await _apiService.createQuote(
      companyName: companyName,
      companyLocation: companyLocation,
      attentionName: attentionName,
      attentionPosition: attentionPosition,
      customerProject: customerProject,
      projectLocation: projectLocation,
      createdBy: createdBy,
      items: items,
    );
  }

  /// Get equipment types from API
  Future<List<dynamic>> getEquipmentTypes() async {
    final result = await _apiService.getEquipmentTypes();
    if (result['success'] == true) {
      return result['data'] as List<dynamic>;
    }
    throw Exception(result['message'] ?? 'Failed to load equipment types');
  }

  // ==================== Local Storage Methods (Legacy/Fallback) ====================

  /// Get all saved quotes from local storage
  Future<List<Quote>> getAllLocal() async {
    final prefs = await _preferences;
    final jsonString = prefs.getString(AppConstants.quotesStorageKey);
    if (jsonString == null || jsonString.isEmpty) {
      // No quotes found
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);

      final quotes = <Quote>[];
      for (final j in jsonList) {
        try {
          quotes.add(Quote.fromJson(j));
        } catch (e) {
          // Skip invalid quotes - don't let one bad quote break everything
          continue;
        }
      }
      
      quotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return quotes;
    } catch (e) {
      // If JSON is corrupt, return empty list instead of crashing
      return [];
    }
  }

  /// Save a quote locally (creates or updates)
  Future<void> saveLocal(Quote quote) async {
    try {
      final prefs = await _preferences;
      final quotes = await getAllLocal();



      final index = quotes.indexWhere((q) => q.id == quote.id);
      if (index >= 0) {
        quotes[index] = quote;

      } else {
        quotes.add(quote);

      }

      final jsonList = quotes.map((q) => q.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      

      
      await prefs.setString(AppConstants.quotesStorageKey, jsonString);

    } catch (e) {
      throw Exception('Failed to save quote: $e');
    }
  }

  /// Delete a quote by ID from local storage
  Future<void> deleteLocal(String id) async {
    final prefs = await _preferences;
    final quotes = await getAllLocal();
    quotes.removeWhere((q) => q.id == id);

    final jsonList = quotes.map((q) => q.toJson()).toList();
    await prefs.setString(AppConstants.quotesStorageKey, jsonEncode(jsonList));
  }

  /// Get a single quote by ID from local storage
  Future<Quote?> getByIdLocal(String id) async {
    final quotes = await getAllLocal();
    try {
      return quotes.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update quote status locally
  Future<void> updateStatusLocal(String id, QuoteStatus status) async {
    final quote = await getByIdLocal(id);
    if (quote != null) {
      // Create updated quote with new status
      final updatedQuote = quote.copyWith(status: status);
      await saveLocal(updatedQuote);
    }
  }

  /// Update quote status (uses API when logged in, local otherwise)
  Future<bool> updateStatus(String id, String refNo, QuoteStatus status) async {
    // Convert status enum to string
    final statusString = status.name; // pending, approved, rejected, expired
    
    if (useApi) {
      // Try to update via API first
      final result = await _apiService.updateStatus(refNo, statusString);
      if (result['success'] == true) {
        // Also update local storage to keep in sync
        await updateStatusLocal(id, status);
        return true;
      }
      // If API fails, fall back to local
    }
    
    // Update locally
    await updateStatusLocal(id, status);
    return true;
  }

  /// Search quotes in local storage
  Future<List<Quote>> searchLocal(String query) async {
    final quotes = await getAllLocal();
    if (query.isEmpty) return quotes;

    final q = query.toLowerCase();
    return quotes.where((quote) {
      return quote.refNo.toLowerCase().contains(q) ||
          quote.company.toLowerCase().contains(q) ||
          quote.projectLocation.toLowerCase().contains(q);
    }).toList();
  }

  /// Clear all local quotes
  Future<void> clearAllLocal() async {
    final prefs = await _preferences;
    await prefs.remove(AppConstants.quotesStorageKey);
  }

  // ==================== Helper Methods ====================

  /// Convert API quote data to local Quote model
  Quote apiQuoteToLocalQuote(Map<String, dynamic> apiQuote) {
    // Convert API items to QuoteItem objects if available
    List<QuoteItem> items = [];
    if (apiQuote['items'] != null && apiQuote['items'] is List) {
      items = (apiQuote['items'] as List).map((item) {
        return QuoteItem(
          section: item['section'] ?? 'General',
          description: item['description'] ?? '',
          neckSize: item['neck_size'] ?? '${item['length']?.toString() ?? ''} x ${item['width']?.toString() ?? ''}',
          qty: item['qty'] ?? 1,
          unitPrice: double.tryParse(item['final_unit_price']?.toString() ?? '0') ?? 0,
        );
      }).toList();
    }

    return Quote(
      id: apiQuote['id'].toString(),
      refNo: apiQuote['reference_no'] ?? apiQuote['quote_no'] ?? '',
      date: DateTime.parse(apiQuote['created_at'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(apiQuote['created_at'] ?? DateTime.now().toIso8601String()),
      company: apiQuote['company_name'] ?? apiQuote['customer_name'] ?? '',
      companyLocation: apiQuote['company_location'] ?? '',
      attention: apiQuote['attention_name'] ?? '',
      attentionTitle: apiQuote['attention_position'] ?? '',
      paymentTerms: AppConstants.defaultPaymentTerms,
      projectLocation: apiQuote['project_location'] ?? '',
      supplyDescription: AppConstants.defaultSupplyDescription,
      leadtime: AppConstants.defaultLeadtime,
      items: items,
      status: _parseStatus(apiQuote['status']),
    );
  }

  QuoteStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return QuoteStatus.approved;
      case 'rejected':
        return QuoteStatus.rejected;
      case 'expired':
        return QuoteStatus.expired;
      default:
        return QuoteStatus.pending;
    }
  }
}
