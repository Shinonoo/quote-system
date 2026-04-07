class Product {
  final String name;
  final String model;
  final String? description;
  final List<String> materials;
  final String unit;
  final List<String> customizations;
  final double basePrice;           // flat minimum price (≤ 250x250)
  final Map<String, double> multipliers; // material → rate for formula
  final Map<int, double>? roundPrices;   // inch size → price (round products only)

  const Product({
    required this.name,
    required this.model,
    this.description,
    this.materials = const ['AL', 'GI'],
    this.unit = 'pcs',
    this.customizations = const [],
    this.basePrice = 500,
    this.multipliers = const {'AL': 6.5, 'GI': 6.5},
    this.roundPrices,
  });

  // <-- True when product uses inch lookup table instead of formula -->
  bool get isRound => roundPrices != null;

  // <-- Returns multiplier for the selected material, falls back to first -->
  double multiplierFor(String material) =>
      multipliers[material] ?? multipliers.values.first;

  String get displayName => '$model - $name';
  String get materialsText => materials.join('/');
}

const kProducts = [
  // ─── Diffusers ────────────────────────────────────────────────────
  Product(
    name: 'Square Ceiling Diffuser; 4-Way',
    model: 'SCD',
    description: 'Square ceiling diffuser with 4-way air pattern',
    customizations: ['obvd', 'bird', 'insect', 'powder', 'acrylic', 'railing'],
    basePrice: 800,
    multipliers: {'AL': 6.5, 'GI': 5.5},
    // materials defaults to ['AL', 'GI'] ✅
  ),
  Product(
    name: 'Round Ceiling Diffuser; 4-Way',
    model: 'RCD',
    description: 'Round ceiling diffuser with 4-way air pattern. Aluminum only',
    materials: ['AL'],                   // ← AL only
    customizations: ['radial', 'bird', 'insect'],
    basePrice: 1000,
    multipliers: {'AL': 0},
    roundPrices: {
      6: 1000, 8: 1150, 10: 1450, 12: 1700,
      14: 1850, 16: 2450, 18: 2800, 20: 3150, 24: 3550,
    },
  ),

  // ─── Air Grilles ──────────────────────────────────────────────────
  Product(
    name: 'Single Deflection Air Grille - Movable Blade',
    model: 'SAG-SD',
    customizations: ['obvd', 'bird', 'insect', 'powder', 'acrylic'],
    basePrice: 550,
    multipliers: {'AL': 6.0, 'GI': 4.5},
    // materials defaults to ['AL', 'GI'] 
  ),
  Product(
    name: 'Double Deflection Air Grille - Movable Blade',
    model: 'SAG-DD',
    customizations: ['obvd', 'bird', 'insect', 'powder', 'acrylic'],
    basePrice: 650,
    multipliers: {'AL': 7.0, 'GI': 5.5},
    // materials defaults to ['AL', 'GI'] 
  ),
  Product(
    name: 'Linear Bar Grille - Horizontal Blade (Fixed)',
    model: 'LBG-A',
    customizations: ['obvd', 'bird', 'insect', 'powder', 'acrylic'],
    basePrice: 550,
    multipliers: {'AL': 6.0, 'GI': 5.0},
    // materials defaults to ['AL', 'GI'] 
  ),

  // ─── Louvers ──────────────────────────────────────────────────────
  Product(
    name: 'Louver Grille - 45 Degrees Fixed Blade',
    model: 'GL-OBB',
    customizations: ['bird', 'insect', 'powder', 'acrylic'],
    basePrice: 550,
    multipliers: {'AL': 6.0, 'GI': 4.5},
    // materials defaults to ['AL', 'GI'] 
  ),
  Product(
    name: 'Air Louver - Z Type Blade (Outdoor Type)',
    model: 'AL-45',
    customizations: ['bird', 'insect', 'powder', 'acrylic'],
    basePrice: 550,
    multipliers: {'AL': 6.0, 'GI': 6.0},
    // materials defaults to ['AL', 'GI'] 
  ),
  Product(
    name: 'Air Louver - Z Type Blade (Outdoor Type)',
    model: 'AL-75',
    materials: ['AL'],                   // ← AL only, matches multipliers
    customizations: ['bird', 'insect', 'powder', 'acrylic'],
    basePrice: 550,
    multipliers: {'AL': 10.0},
  ),
  Product(
    name: 'Air Louver - Z Type Blade (Weatherproof)',
    model: 'WAL-75',
    customizations: ['bird', 'insect', 'powder', 'acrylic'],
    basePrice: 1000,
    multipliers: {'AL': 10.0, 'GI': 6.0},
    // materials defaults to ['AL', 'GI'] 
  ),

  // ─── Dampers & Others ─────────────────────────────────────────────
  Product(
    name: 'Volume Damper (Lever-operated)',
    model: 'VD',
    materials: ['GI'],                   // ← GI only, matches multipliers
    basePrice: 700,
    multipliers: {'GI': 7.5},
  ),
  Product(
    name: 'Motorized Damper + Actuator',
    model: 'MD',
    materials: ['GI'],                   // ← GI only
    basePrice: 700,
    multipliers: {'GI': 7.5},
  ),
  Product(
    name: 'Motorized Damper without Actuator',
    model: 'MD',
    materials: ['GI'],                   // ← GI only
    basePrice: 700,
    multipliers: {'GI': 7.5},
  ),
  Product(
    name: 'Motorized Fire & Smoke Damper + Actuator',
    model: 'MFSD',
    materials: ['GI'],                   // ← GI only
    basePrice: 700,
    multipliers: {'GI': 7.5},
  ),
  Product(
    name: 'Backdraft Damper',
    model: 'BFSD',
    materials: ['GI'],                   // ← GI only
    basePrice: 700,
    multipliers: {'GI': 7.5},
  ),
  Product(
    name: 'Fire Damper with Fusible Link',
    model: 'FFSD',
    materials: ['GI'],                   // ← GI only
    basePrice: 800,
    multipliers: {'GI': 8.0},
  ),
];

/// Search products by name or model code
List<Product> searchProducts(String query) {
  if (query.isEmpty) return [];
  final q = query.toLowerCase();
  return kProducts.where((p) {
    return p.name.toLowerCase().contains(q) ||
        p.model.toLowerCase().contains(q);
  }).toList();
}

/// Display name for a customization key
String getCustomizationDisplayName(String key) {
  const names = {
    'obvd':    'OBVD',
    'bird':    'Bird',
    'insect':  'Insect',
    'powder':  'Powder Coating',
    'acrylic': 'Acrylic',
    'radial':  'Radial',
    'railing': 'Railing',
  };
  return names[key] ?? key;
}

/// Price/multiplier info shown in the UI next to each customization
String getCustomizationInfo(String key) {
  const info = {
    'obvd':    '+50%',
    'bird':    '+20%',
    'insect':  '+15%',
    'powder':  '+₱500',
    'acrylic': '+10%',
    'radial':  '+30%',
    'railing': '+10%',
  };
  return info[key] ?? '';
}