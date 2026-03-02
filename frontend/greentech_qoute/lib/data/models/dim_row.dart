import 'package:flutter/material.dart';
import 'custom_customization.dart';

class DimRow {
  final TextEditingController lengthCtrl;
  final TextEditingController widthCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController customReqCtrl;
  final List<CustomCustomization> customCustomizations;

  bool insect = false;
  bool bird = false;
  bool obvd = false;
  bool radial = false;
  bool doubleFrame = false;
  bool powderCoat = false;
  String paintFinish = 'matte';
  String paintColor = 'white';
  bool isExpanded = false;

  DimRow({String length = '', String width = '', String qty = '1', String req = ''})
      : lengthCtrl = TextEditingController(text: length),
        widthCtrl = TextEditingController(text: width),
        qtyCtrl = TextEditingController(text: qty),
        customReqCtrl = TextEditingController(text: req),
        customCustomizations =[];

  void dispose() {
    lengthCtrl.dispose();
    widthCtrl.dispose();
    qtyCtrl.dispose();
    customReqCtrl.dispose();
    for (var cc in customCustomizations) {
      cc.dispose();
    }
  }
}
