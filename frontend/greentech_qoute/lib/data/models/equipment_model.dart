class EquipmentModel {
  final int id;
  final String name;
  final String code;
  final double baseDivisor;
  final double baseMultiplier;
  final double finalMultiplier;
  final List<String> allowedCustomizations;

  EquipmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.baseDivisor,
    required this.baseMultiplier,
    required this.finalMultiplier,
    required this.allowedCustomizations,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      baseDivisor: (json['base_divisor'] as num).toDouble(),
      baseMultiplier: (json['base_multiplier'] as num).toDouble(),
      finalMultiplier: (json['final_multiplier'] as num).toDouble(),
      allowedCustomizations: List<String>.from(json['allowed_customizations'] ?? []),
    );
  }
}