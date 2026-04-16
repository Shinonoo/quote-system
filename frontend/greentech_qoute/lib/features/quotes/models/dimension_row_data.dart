import 'package:flutter/material.dart';
import '../services/actuator_service.dart'; // Check this import path based on your setup

class DimensionRowData {
  final TextEditingController lengthMmController;
  final TextEditingController widthMmController;
  final TextEditingController qtyController;

  int    qty;
  bool   isValid;
  bool   inputInMm;
  double previewPrice;
  ActuatorSelection? actuatorSelection;

  Set<String> customizations;
  String?     selectedColor;
  String      customColorText;
  bool        hasCustomOverride;

  DimensionRowData({
    TextEditingController? lengthMmController,
    TextEditingController? widthMmController,
    TextEditingController? qtyController,
    this.qty               = 1,
    this.isValid           = false,
    this.inputInMm         = false,
    this.previewPrice      = 0.0,
    this.actuatorSelection,
    Set<String>?           customizations,
    this.selectedColor,
    this.customColorText   = '',
    this.hasCustomOverride = false,
  })  : lengthMmController = lengthMmController ?? TextEditingController(),
        widthMmController  = widthMmController  ?? TextEditingController(),
        qtyController      = qtyController      ?? TextEditingController(text: '1'),
        customizations     = customizations     ?? {};

  void dispose() {
    lengthMmController.dispose();
    widthMmController.dispose();
    qtyController.dispose();
  }
}