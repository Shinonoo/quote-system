/// Represents a single item in a quotation
class QuoteItem {
  final String section;
  final String description;
  final String neckSize;
  final int qty;
  final double unitPrice;
  final String? material;
  final String unit;
  final List<String> customizations;

  const QuoteItem({
    required this.section,
    required this.description,
    required this.neckSize,
    required this.qty,
    required this.unitPrice,
    this.material,
    this.unit = 'pcs',
    this.customizations = const [],
  });

  double get total => qty * unitPrice;

  String get fullDescription {
    final buffer = StringBuffer(description);
    if (material != null && material!.isNotEmpty) {
      buffer.write(' [$material]');
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
        'section': section,
        'description': description,
        'neckSize': neckSize,
        'qty': qty,
        'unitPrice': unitPrice,
        'material': material,
        'unit': unit,
        'customizations': customizations,
      };

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    try {
      return QuoteItem(
        section: json['section'] as String? ?? 'General',
        description: json['description'] as String? ?? '',
        neckSize: json['neckSize'] as String? ?? '',
        qty: (json['qty'] as num?)?.toInt() ?? 0,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
        material: json['material'] as String?,
        unit: json['unit'] as String? ?? 'pcs',
        customizations: (json['customizations'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    } catch (_) {
      rethrow;
    }
  }

  QuoteItem copyWith({
    String? section,
    String? description,
    String? neckSize,
    int? qty,
    double? unitPrice,
    String? material,
    String? unit,
    List<String>? customizations,
  }) {
    return QuoteItem(
      section: section ?? this.section,
      description: description ?? this.description,
      neckSize: neckSize ?? this.neckSize,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      material: material ?? this.material,
      unit: unit ?? this.unit,
      customizations: customizations ?? this.customizations,
    );
  }
}
