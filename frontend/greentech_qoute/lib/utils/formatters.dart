import 'dart:convert';

class Formatters {
  static String parseDate(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return 'N/A';
    try {
      return raw.toString().split('T')[0];
    } catch (_) {
      return 'N/A';
    }
  }

  static String formatPrice(dynamic value) {
    if (value == null) return '0.00';
    try {
      return double.parse(value.toString()).toStringAsFixed(2);
    } catch (_) {
      return '0.00';
    }
  }

  static String formatCustomizations(dynamic customJson) {
    if (customJson == null || customJson.toString().isEmpty || customJson == '{}') {
      return '';
    }

    try {
      final Map<String, dynamic> parsed = customJson is String
          ? jsonDecode(customJson)
          : customJson as Map<String, dynamic>;

      final labels = <String>[];

      if (parsed.containsKey('insect_screen')) labels.add('Insect Screen');
      if (parsed.containsKey('bird_screen')) labels.add('Bird Screen');
      if (parsed.containsKey('obvd')) labels.add('OBVD');
      if (parsed.containsKey('radial_damper')) labels.add('Radial Damper');
      if (parsed.containsKey('double_frame')) labels.add('Double Frame');

      if (parsed.containsKey('powder_coat')) {
        final pc = parsed['powder_coat'];
        if (pc is Map) {
          labels.add('Powder Coat (${pc['finish']}, ${pc['color']})');
        } else {
          labels.add('Powder Coat');
        }
      }

      if (parsed.containsKey('custom_req') && parsed['custom_req'].toString().isNotEmpty) {
        labels.add(parsed['custom_req'].toString());
      }

      return labels.isEmpty ? '' : '\nCustom: ${labels.join(', ')}';
    } catch (e) {
      return '';
    }
  }

  static bool isNotEmpty(dynamic value) {
    return value != null && value.toString().isNotEmpty;
  }
}