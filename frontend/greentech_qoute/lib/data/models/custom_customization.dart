import 'package:flutter/material.dart';

class CustomCustomization {
  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController multiplierCtrl;
  String type; // 'fixed' or 'multiplier'

  CustomCustomization({
    String name = '',
    String price = '',
    String multiplier = '1.0',
    this.type = 'fixed',
  })  : nameCtrl = TextEditingController(text: name),
        priceCtrl = TextEditingController(text: price),
        multiplierCtrl = TextEditingController(text: multiplier);

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    multiplierCtrl.dispose();
  }

  Map<String, dynamic> toJson() {
    if (type == 'fixed') {
      return {
        'name': nameCtrl.text,
        'type': 'fixed',
        'price': double.tryParse(priceCtrl.text) ?? 0,
      };
    } else {
      return {
        'name': nameCtrl.text,
        'type': 'multiplier',
        'multiplier': double.tryParse(multiplierCtrl.text) ?? 1.0,
      };
    }
  }
}
