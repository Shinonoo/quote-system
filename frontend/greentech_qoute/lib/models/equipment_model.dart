class EquipmentModel {
  final int id;
  final String name;
  final String code;
  final List<String> allowedCustomizations;

  EquipmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.allowedCustomizations,
  });

  // Converts raw API JSON → EquipmentModel object
  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      allowedCustomizations: List<String>.from(json['allowed_customizations'] ?? []),
    );
  }
}
