enum ActuatorSection {
  nonFire130V('Non-Fire & Smoke (230V)'),
  nonFireMod24V('Non-Fire & Smoke (Modulating 24V)'),
  nonFireMod24VA('Non-Fire & Smoke (Modulating 24V-A)'),
  fireSmoke230VNoAux('Fire & Smoke (230V) w/o Auxiliary'),
  fireSmoke230VAux('Fire & Smoke (230V) w/ Auxiliary'),
  fireSmokeMod24V('Fire & Smoke (Modulating 24V)');

  final String label;
  const ActuatorSection(this.label);
}

class ActuatorModel {
  final String model;
  final double nmRating;
  final double basePrice;
  final bool applyMarkup; // ✅ × 1.1 × 1.5 for Modulating 24V

  const ActuatorModel({
    required this.model,
    required this.nmRating,
    required this.basePrice,
    this.applyMarkup = false,
  });

  double get price => applyMarkup ? basePrice * 1.1 * 1.5 : basePrice;
}

class ActuatorData {
  static const Map<ActuatorSection, List<ActuatorModel>> catalog = {
    ActuatorSection.nonFire130V: [
      ActuatorModel(model: 'CM230',  nmRating: 2,  basePrice: 6800),
      ActuatorModel(model: 'LM230',  nmRating: 5,  basePrice: 7800),
      ActuatorModel(model: 'NM230',  nmRating: 10, basePrice: 10100),
      ActuatorModel(model: 'SM230',  nmRating: 20, basePrice: 12200),
    ],
    ActuatorSection.nonFireMod24V: [
      ActuatorModel(model: 'CM24-SR', nmRating: 2,  basePrice: 9600),
      ActuatorModel(model: 'LM24-SR', nmRating: 5,  basePrice: 10600),
      ActuatorModel(model: 'NM24-SR', nmRating: 10, basePrice: 19100),
      ActuatorModel(model: 'SM24-SR', nmRating: 20, basePrice: 15300),
    ],
    ActuatorSection.nonFireMod24VA: [
      ActuatorModel(model: 'CM24A-SR', nmRating: 8,  basePrice: 5607,  applyMarkup: true),
      ActuatorModel(model: 'LM24A-SR', nmRating: 5,  basePrice: 7406,  applyMarkup: true),
      ActuatorModel(model: 'NM24A-SR', nmRating: 10, basePrice: 10685,  applyMarkup: true),
      ActuatorModel(model: 'SM24A-SR', nmRating: 20, basePrice: 13299, applyMarkup: true),
    ],
    ActuatorSection.fireSmoke230VNoAux: [
      ActuatorModel(model: 'FSTF230US',  nmRating: 2,   basePrice: 11100),
      ActuatorModel(model: 'FSLF230US',  nmRating: 3.5, basePrice: 16400),
      ActuatorModel(model: 'FSNF230US',  nmRating: 8,   basePrice: 21100),
      ActuatorModel(model: 'FSAF230US',  nmRating: 20,  basePrice: 28600),
    ],
    ActuatorSection.fireSmoke230VAux: [
      ActuatorModel(model: 'FSTF230SUS', nmRating: 2,   basePrice: 14100),
      ActuatorModel(model: 'FSLF230SUS', nmRating: 3.5, basePrice: 18800),
      ActuatorModel(model: 'FSNF230SUS', nmRating: 8,   basePrice: 23600),
      ActuatorModel(model: 'FSAF230SUS', nmRating: 20,  basePrice: 31100),
    ],
    ActuatorSection.fireSmokeMod24V: [
      ActuatorModel(model: 'LMQ24A (4Nm)', nmRating: 4, basePrice: 19600),
      ActuatorModel(model: 'LMQ24A (8Nm)', nmRating: 8, basePrice: 20900),
    ],
  };

  /// Returns valid sections based on product type
  static List<ActuatorSection> sectionsFor(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('fire') || name.contains('smoke')) {
      return [
        ActuatorSection.fireSmoke230VNoAux,
        ActuatorSection.fireSmoke230VAux,
        ActuatorSection.fireSmokeMod24V,
      ];
    }
    return [
      ActuatorSection.nonFire130V,
      ActuatorSection.nonFireMod24V,
      ActuatorSection.nonFireMod24VA,
    ];
  }
}