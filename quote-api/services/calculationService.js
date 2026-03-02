class CalculationService {
  static calculateLineItem(equipment_type_id, length, width, customizations, equipmentData = null) {
    let raw_unit_price = 0;
    let description = 'Custom Equipment';
    let calculationDetails = {};

    // Custom entry (-1)
    if (equipment_type_id === -1) {
      raw_unit_price = parseFloat(customizations?.custom_price ?? 0);
      description = customizations?.custom_desc ?? 'Custom Equipment';
    } else {
      // Standard equipment calculation
      const area = parseFloat(length) * parseFloat(width);
      raw_unit_price = (area / parseFloat(equipmentData.base_divisor))
        * parseFloat(equipmentData.base_multiplier)
        * parseFloat(equipmentData.final_multiplier);
      
      description = equipmentData.name;
      
      calculationDetails = {
        area,
        baseDivisor: equipmentData.base_divisor,
        baseMultiplier: equipmentData.base_multiplier,
        finalMultiplier: equipmentData.final_multiplier
      };
    }

    // Apply customization multipliers
    let multiplier = 1.0;
    let customizationCosts = 0;
    
    if (customizations) {
      if (customizations.insect_screen) multiplier *= parseFloat(customizations.insect_screen);
      if (customizations.bird_screen) multiplier *= parseFloat(customizations.bird_screen);
      if (customizations.obvd) multiplier *= parseFloat(customizations.obvd);
      if (customizations.radial_damper) multiplier *= parseFloat(customizations.radial_damper);
      if (customizations.double_frame) multiplier *= parseFloat(customizations.double_frame);
      if (customizations.powder_coat) {
        customizationCosts += parseFloat(customizations.powder_coat?.price ?? 500);
      }
    }

    const final_unit_price = (raw_unit_price * multiplier) + customizationCosts;
    
    return {
      description,
      raw_unit_price,
      final_unit_price,
      multiplier,
      customizationCosts,
      calculationDetails
    };
  }

  static generateQuoteNumber() {
    return `QT-${Date.now()}`;
  }

  static generateReferenceNumber(prefix = 'GT') {
    const now = new Date();
    const pad = (n) => String(n).padStart(2, '0');
    return `${prefix}-${now.getFullYear()}-${pad(now.getMonth() + 1)}${pad(now.getDate())}-${Date.now().toString().slice(-3)}`;
  }
}

module.exports = CalculationService;