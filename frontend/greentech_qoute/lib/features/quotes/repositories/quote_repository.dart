import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/quote.dart';
import '../models/quote_item.dart';
import '../services/quote_api_service.dart';
import '../../auth/services/auth_service.dart';

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

  bool get useApi => AuthService().isLoggedIn;

  // ==================== API Methods ====================

  Future<List<dynamic>> getAllFromApi() async {
    final result = await _apiService.getAllQuotes();
    if (result['success'] == true) {
      return result['data'] as List<dynamic>;
    }
    throw Exception(result['message'] ?? 'Failed to load quotes');
  }

  Future<Map<String, dynamic>?> getByQuoteNoFromApi(String refNo) async {
    final result = await _apiService.getQuoteByNo(refNo);
    if (result['success'] == true) {
      return result['data'] as Map<String, dynamic>;
    }
    return null;
  }

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

  Future<List<dynamic>> getEquipmentTypes() async {
    final result = await _apiService.getEquipmentTypes();
    if (result['success'] == true) {
      return result['data'] as List<dynamic>;
    }
    throw Exception(result['message'] ?? 'Failed to load equipment types');
  }

  // ==================== Local Storage Methods ====================

  Future<List<Quote>> getAllLocal() async {
    final prefs = await _preferences;
    final jsonString = prefs.getString(AppConstants.quotesStorageKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final quotes = <Quote>[];
      for (final j in jsonList) {
        try {
          quotes.add(Quote.fromJson(j));
        } catch (_) {
          continue;
        }
      }
      quotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return quotes;
    } catch (_) {
      return [];
    }
  }

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
      await prefs.setString(
        AppConstants.quotesStorageKey,
        jsonEncode(quotes.map((q) => q.toJson()).toList()),
      );
    } catch (e) {
      throw Exception('Failed to save quote: $e');
    }
  }

  Future<void> deleteLocal(String id) async {
    final prefs = await _preferences;
    final quotes = await getAllLocal();
    quotes.removeWhere((q) => q.id == id);
    await prefs.setString(
      AppConstants.quotesStorageKey,
      jsonEncode(quotes.map((q) => q.toJson()).toList()),
    );
  }

  Future<Quote?> getByIdLocal(String id) async {
    final quotes = await getAllLocal();
    try {
      return quotes.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateStatusLocal(String id, QuoteStatus status) async {
    final quote = await getByIdLocal(id);
    if (quote != null) {
      await saveLocal(quote.copyWith(status: status));
    }
  }

  Future<bool> updateStatus(String id, String refNo, QuoteStatus status) async {
    // ✅ Map Flutter enum to backend-accepted strings
    final statusString = _statusToApiString(status);

    if (useApi) {
      final result = await _apiService.updateStatus(refNo, statusString);
      if (result['success'] == true) {
        await updateStatusLocal(id, status);
        return true;
      }
    }

    await updateStatusLocal(id, status);
    return true;
  }

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

  Future<void> clearAllLocal() async {
    final prefs = await _preferences;
    await prefs.remove(AppConstants.quotesStorageKey);
  }

  // ==================== Helper Methods ====================

  /// ✅ Convert API quote (new schema) to local Quote model
  Quote apiQuoteToLocalQuote(Map<String, dynamic> q) {
    List<QuoteItem> items = [];

    if (q['items'] != null && q['items'] is List) {
      items = (q['items'] as List).map((item) {
        // ✅ width + height replace neck_size; quantity replaces qty
        final w = item['width']?.toString() ?? '';
        final h = item['height']?.toString() ?? '';
        final neckSize = (w.isNotEmpty && h.isNotEmpty)
            ? '${w}mm x ${h}mm'
            : item['product_model'] ?? '';

        return QuoteItem(
          section:     item['section']       ?? 'General',
          description: item['product_name']  ?? item['description'] ?? '',
          neckSize:    neckSize,
          qty:         item['quantity']      ?? item['qty'] ?? 1,         // ✅ quantity
          unitPrice:   double.tryParse(
                         item['unit_price']?.toString() ?? '0'            // ✅ unit_price
                       ) ?? 0,
        );
      }).toList();
    }

    return Quote(
      id:               q['id'].toString(),
      refNo:            q['ref_no']            ?? '',                     // ✅ ref_no
      date:             DateTime.tryParse(q['created_at'] ?? '') ?? DateTime.now(),
      createdAt:        DateTime.tryParse(q['created_at'] ?? '') ?? DateTime.now(),
      company:          q['customer_company']  ?? q['customer_name'] ?? '', // ✅ customer_company
      companyLocation:  q['company_location']  ?? '',
      attention:        q['attention_name']    ?? '',
      attentionTitle:   q['attention_position'] ?? '',
      paymentTerms:     q['payment_terms']     ?? AppConstants.defaultPaymentTerms,
      projectLocation:  q['project_location']  ?? '',
      supplyDescription: q['supply_description'] ?? AppConstants.defaultSupplyDescription,
      leadtime:         q['leadtime']           ?? AppConstants.defaultLeadtime,
      items:            items,
      status:           _parseStatus(q['status']),
    );
  }

  /// ✅ Backend statuses → Flutter QuoteStatus
  QuoteStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':        return QuoteStatus.approved;
      case 'rejected':        return QuoteStatus.rejected;
      case 'expired':         return QuoteStatus.expired;
      case 'sent':            return QuoteStatus.pending;
      case 'draft':
      default:                return QuoteStatus.pending;
    }
  }

  /// ✅ Flutter QuoteStatus → backend-accepted string
  String _statusToApiString(QuoteStatus status) {
    switch (status) {
      case QuoteStatus.approved: return 'approved';
      case QuoteStatus.rejected: return 'rejected';
      case QuoteStatus.expired:  return 'expired';
      case QuoteStatus.pending:
      default:                   return 'sent'; // pending = sent to client
    }
  }
}