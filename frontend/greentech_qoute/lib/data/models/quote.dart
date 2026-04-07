import 'quote_item.dart';

enum QuoteStatus { pending, approved, rejected, expired }

/// Represents a complete quotation
class Quote {
  final String id;
  final String refNo;
  final DateTime date;
  final DateTime createdAt;
  final String company;
  final String companyLocation;
  final String attention;
  final String attentionTitle;
  final String paymentTerms;
  final String projectLocation;
  final String supplyDescription;
  final String leadtime;
  final List<QuoteItem> items;
  QuoteStatus status;

  Quote({
    String? id,
    required this.refNo,
    required this.date,
    DateTime? createdAt,
    required this.company,
    required this.companyLocation,
    required this.attention,
    required this.attentionTitle,
    required this.paymentTerms,
    required this.projectLocation,
    required this.supplyDescription,
    required this.leadtime,
    required this.items,
    this.status = QuoteStatus.pending,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  double get total => items.fold(0.0, (sum, item) => sum + item.total);

  int get totalQty => items.fold(0, (sum, item) => sum + item.qty);

  int get itemCount => items.length;

  Map<String, List<QuoteItem>> get groupedBySection {
    final map = <String, List<QuoteItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.section, () => []).add(item);
    }
    return map;
  }

  String get statusLabel {
    switch (status) {
      case QuoteStatus.pending:
        return 'Pending';
      case QuoteStatus.approved:
        return 'Approved';
      case QuoteStatus.rejected:
        return 'Rejected';
      case QuoteStatus.expired:
        return 'Expired';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'refNo': refNo,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'company': company,
        'companyLocation': companyLocation,
        'attention': attention,
        'attentionTitle': attentionTitle,
        'paymentTerms': paymentTerms,
        'projectLocation': projectLocation,
        'supplyDescription': supplyDescription,
        'leadtime': leadtime,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.index,
      };

  factory Quote.fromJson(Map<String, dynamic> json) {
    List<QuoteItem> parsedItems = [];
    try {
      final itemsJson = json['items'];
      if (itemsJson != null && itemsJson is List) {
        parsedItems = itemsJson
            .map((i) => QuoteItem.fromJson(i as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    
    return Quote(
      id: json['id'] as String,
      refNo: json['refNo'] as String,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      company: json['company'] as String,
      companyLocation: json['companyLocation'] as String,
      attention: json['attention'] as String,
      attentionTitle: json['attentionTitle'] as String,
      paymentTerms: json['paymentTerms'] as String,
      projectLocation: json['projectLocation'] as String,
      supplyDescription: json['supplyDescription'] as String,
      leadtime: json['leadtime'] as String,
      items: parsedItems,
      status: QuoteStatus.values[json['status'] as int],
    );
  }

  Quote copyWith({
    String? id,
    String? refNo,
    DateTime? date,
    DateTime? createdAt,
    String? company,
    String? companyLocation,
    String? attention,
    String? attentionTitle,
    String? paymentTerms,
    String? projectLocation,
    String? supplyDescription,
    String? leadtime,
    List<QuoteItem>? items,
    QuoteStatus? status,
  }) {
    return Quote(
      id: id ?? this.id,
      refNo: refNo ?? this.refNo,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      company: company ?? this.company,
      companyLocation: companyLocation ?? this.companyLocation,
      attention: attention ?? this.attention,
      attentionTitle: attentionTitle ?? this.attentionTitle,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      projectLocation: projectLocation ?? this.projectLocation,
      supplyDescription: supplyDescription ?? this.supplyDescription,
      leadtime: leadtime ?? this.leadtime,
      items: items ?? this.items,
      status: status ?? this.status,
    );
  }
}
