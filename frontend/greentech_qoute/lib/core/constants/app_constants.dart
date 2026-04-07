/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Greentech Quote';
  static const String companyName = 'GREENTECH INDL INC';
  static const String companyTagline =
      '" Your partner in AIR TERMINALS, INSULATIONS, HVAC Products & MERV FILTERS "';

  // Contact Info
  static const String companyAddress =
      'Address: 17 Pescadores Pag-asa 4309 Macalelon Quezon Philippines';
  static const String companyPhone = 'Tel: (028) 736-8876';
  static const String companyFax = 'Fax: (028) 828-2496';
  static const String companyWireless = 'Wireless: (028) 782-6117 / 985-8441';
  static const String companyEmail = 'sales@greentechindl.com';
  static const String companyWebsite = 'www.greentechindl.com';

  // Default Values
  static const String defaultPaymentTerms = '30 DAYS POST DATED CHECK';
  static const String defaultSupplyDescription = 'SUPPLY OF AIR TERMINALS (Local)';
  static const String defaultLeadtime =
      'PRODUCTION WILL START UPON RECEIPT OF THE PURCHASE ORDER AND APPROVED SUBMITTALS';

  // Currency
  static const String currencySymbol = '₱';
  static const String currencyLocale = 'en_PH';

  // Storage Keys
  static const String quotesStorageKey = 'quotes';

  // Ref No Prefix
  static String get refNoPrefix => 'JDP-${DateTime.now().year}-';

  // PDF Terms
  static const List<String> pdfTerms = [
    '• VALIDITY: (15) FIFTEEN DAYS FROM THE DATE OF QUOTATION',
    '• Price is Supply only. Hauling, Rigging, Positioning and Installation are excluded.',
    '• For Purchase Orders above PHP 50,000, delivery is free within Metro Manila. Below PHP 50,000 is for warehouse pickup.',
    '• Delivery within Metro Manila only; Outside Metro Manila will require additional cost.',
    '• Delivery is unloading only, exclusive of hauling and any other works.',
    '• NO WARRANTY ON SUPPLIED MATERIAL. Kindly check item upon receiving.',
    '• NO WARRANTY ON PAINT. Kindly check item upon receiving.',
    '• Upon cancellation, buyer shall pay 25% cancellation fee and 25% re-stocking fee.',
    '• Additional/change of measurements, materials and equipment will require additional cost.',
  ];

  static const List<String> pdfNotes = [
    '1. G.I - Galvanized iron; AL - Aluminum',
    '2. STANDARD ENAMEL PAINT (WHITE) unless specified (For Air grilles only).',
    '3. For approval of sample & shop drawing (if necessary).',
    '4. All works NOT mentioned in the proposal are Excluded.',
  ];

  // Staff Info
  static const Map<String, Map<String, String>> staffInfo = {
    'roy': {
      'name': 'Engr. Roy Benitez',
      'title': 'Senior Sales Engineer',
      'mobile': '+632 933 869 7479',
      'email': 'rcbenitez@greentechindl.com',
    },
    'issah': {
      'name': 'Ms. Issah G. Doria',
      'title': 'Sales Manager',
      'mobile': '+632 933 812 4607',
      'email': 'cgd@greentechindl.com',
    },
  };
}
