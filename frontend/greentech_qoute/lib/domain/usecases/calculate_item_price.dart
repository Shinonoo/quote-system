import '../../data/models/equipment_model.dart';

class CalculateItemPrice {
  static Map<String, dynamic> execute({
    required int equipmentTypeId,
    required double length,
    required double width,
    int qty = 1,
    Map<String, dynamic>? customizations,
    EquipmentModel? equipmentData, // For standard items
    Map<String, dynamic>? customEntry, // For custom items (-1)
  }) {
    // Custom entry logic
    if (equipmentTypeId == -1) {
      final price = (customEntry?['custom_price'] as num?)?.toDouble() ?? 0;
      return {
        'description': customEntry?['custom_desc'] ?? 'Custom Equipment',
        'raw_unit_price': price,
        'final_unit_price': price,
        'line_total': price * qty,
      };
    }

    // Standard calculation (from your SQL schema)
    final area = length * width;
    double rawPrice = (area / equipmentData!.baseDivisor) 
        * equipmentData.baseMultiplier 
        * equipmentData.finalMultiplier;

    // Apply multipliers
    double multiplier = 1.0;
    double additionalCost = 0.0;

    if (customizations != null) {
      if (customizations['insect_screen'] != null) multiplier *= 1.2;
      if (customizations['bird_screen'] != null) multiplier *= 1.5;
      if (customizations['obvd'] != null) multiplier *= 1.3;
      if (customizations['radial_damper'] != null) multiplier *= 1.4;
      if (customizations['double_frame'] != null) multiplier *= 1.15;
      if (customizations['powder_coat'] != null) {
        additionalCost += (customizations['powder_coat']['price'] as num?)?.toDouble() ?? 500;
      }
      
      // Custom modifiers
      if (customizations['custom_modifiers'] != null) {
        for (var mod in customizations['custom_modifiers']) {
          if (mod['type'] == 'multiplier') {
            multiplier *= (mod['multiplier'] as num).toDouble();
          } else if (mod['type'] == 'fixed') {
            additionalCost += (mod['price'] as num).toDouble();
          }
        }
      }
    }

    final finalPrice = (rawPrice * multiplier) + additionalCost;
    
    return {
      'description': equipmentData.name,
      'raw_unit_price': rawPrice,
      'final_unit_price': finalPrice,
      'line_total': finalPrice * qty,
      'calculation_breakdown': {
        'area': area,
        'multiplier': multiplier,
        'additional_cost': additionalCost,
      }
    };
  }
}
