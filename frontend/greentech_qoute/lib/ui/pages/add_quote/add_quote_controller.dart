import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/products.dart';
import '../../../data/models/quote.dart';
import '../../../data/models/quote_item.dart';
import '../../../data/repositories/quote_repository.dart';
import '../../../data/services/auth_service.dart';

// <-- Data class representing a single dimension row -->
class DimensionRowData {
  TextEditingController lengthMmController;
  TextEditingController widthMmController;
  TextEditingController qtyController;
  int qty;
  bool isValid;
  bool inputInMm; // <-- true = user types mm, false = user types inches

  DimensionRowData({
    TextEditingController? lengthMmController,
    TextEditingController? widthMmController,
    TextEditingController? qtyController,
    this.qty = 1,
    this.isValid = false,
    this.inputInMm = false, // <-- default to inches
  })  : lengthMmController = lengthMmController ?? TextEditingController(),
        widthMmController = widthMmController ?? TextEditingController(),
        qtyController = qtyController ?? TextEditingController(text: '1');

  void dispose() {
    lengthMmController.dispose();
    widthMmController.dispose();
    qtyController.dispose();
  }
}

// <-- Controller for managing Add Quote page state -->
class AddQuoteController extends ChangeNotifier {
  final Quote? editQuote;
  final void Function(String)? onError;
  final void Function(String)? onSuccess;

  // <-- Text Controllers -->
  final TextEditingController refNoCtrl = TextEditingController();
  final TextEditingController companyCtrl = TextEditingController();
  final TextEditingController locationCtrl = TextEditingController();
  final TextEditingController attentionCtrl = TextEditingController();
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController projectCtrl = TextEditingController();
  final TextEditingController supplyDescCtrl = TextEditingController();
  final TextEditingController paymentCtrl = TextEditingController();
  final TextEditingController leadtimeCtrl = TextEditingController();
  final TextEditingController sectionCtrl = TextEditingController();
  final TextEditingController customColorCtrl = TextEditingController();

  // <-- State Variables -->
  DateTime selectedDate = DateTime.now();
  Product? selectedProduct;
  String selectedMaterial = '';
  Set<String> selectedCustomizations = {};
  String? selectedColor;
  List<QuoteItem> items = [];
  List<DimensionRowData> dimensionRows = [];
  bool isSaving = false;

  final List<String> standardColors = [
    'White', 'Black', 'Gray', 'Ivory', 'Beige', 'Custom',
  ];

  static const double _markupDealer = 1.2;
  static const double _markupVat = 1.1;
  static const int _minPricingDimension = 250;

  final QuoteRepository _repository = QuoteRepository();

  AddQuoteController({
    this.editQuote,
    this.onError,
    this.onSuccess,
  }) {
    _initialize();
  }

  // <-- ============ Initialization ============ -->

  void _initialize() {
    supplyDescCtrl.text = AppConstants.defaultSupplyDescription;
    paymentCtrl.text = AppConstants.defaultPaymentTerms;
    leadtimeCtrl.text = AppConstants.defaultLeadtime;

    if (editQuote != null) {
      _populateFromEditQuote();
    } else {
      refNoCtrl.text = '${AppConstants.refNoPrefix}${_generateRefSuffix()}';
    }

    addDimensionRow();
  }

  void _populateFromEditQuote() {
    final quote = editQuote!;
    refNoCtrl.text = quote.refNo;
    selectedDate = quote.date;
    companyCtrl.text = quote.company;
    locationCtrl.text = quote.companyLocation;
    attentionCtrl.text = quote.attention;
    titleCtrl.text = quote.attentionTitle;
    projectCtrl.text = quote.projectLocation;
    supplyDescCtrl.text = quote.supplyDescription;
    paymentCtrl.text = quote.paymentTerms;
    leadtimeCtrl.text = quote.leadtime;
    items = List.from(quote.items);
  }

  String _generateRefSuffix() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecond.toString().padLeft(3, '0')}';
  }

  // <-- ============ Setters ============ -->

  void setSelectedDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setSelectedProduct(Product? product) {
    selectedProduct = product;
    selectedMaterial = product?.materials.first ?? '';
    selectedCustomizations.clear();
    selectedColor = null;
    customColorCtrl.clear();
    notifyListeners();
  }

  void setSelectedMaterial(String material) {
    selectedMaterial = material;
    notifyListeners();
  }

  void toggleCustomization(String customization) {
    if (selectedCustomizations.contains(customization)) {
      selectedCustomizations.remove(customization);
      if (customization == 'powder' || customization == 'acrylic') {
        if (!selectedCustomizations.contains('powder') &&
            !selectedCustomizations.contains('acrylic')) {
          selectedColor = null;
          customColorCtrl.clear();
        }
      }
    } else {
      selectedCustomizations.add(customization);
    }
    notifyListeners();
  }

  void setSelectedColor(String? color) {
    selectedColor = color;
    if (color != 'Custom') customColorCtrl.clear();
    notifyListeners();
  }

  // <-- ============ Dimension Rows ============ -->

  void addDimensionRow() {
    dimensionRows.add(DimensionRowData());
    notifyListeners();
  }

  void removeDimensionRow(int index) {
    if (index >= 0 && index < dimensionRows.length) {
      dimensionRows[index].dispose();
      dimensionRows.removeAt(index);
      notifyListeners();
    }
  }

  // <-- Toggles mm/inch mode for a round product row and clears the input -->
  void toggleInputUnit(int index) {
    if (index < 0 || index >= dimensionRows.length) return;
    final row = dimensionRows[index];
    row.inputInMm = !row.inputInMm;
    row.lengthMmController.clear();
    row.isValid = false;
    notifyListeners();
  }

  void onLengthMmChanged(int index, String value) {
    if (index < 0 || index >= dimensionRows.length) return;
    final row = dimensionRows[index];
    final input = double.tryParse(value);

    if (selectedProduct?.isRound == true) {
      if (input == null || input <= 0) {
        row.isValid = false;
      } else if (row.inputInMm) {
        // <-- Convert mm → inch, check if it matches a valid size in the table -->
        final inch = (input / 25.4).round();
        row.isValid = selectedProduct!.roundPrices!.containsKey(inch);
      } else {
        // <-- Direct inch input -->
        final inch = input.round();
        row.isValid = selectedProduct!.roundPrices!.containsKey(inch);
      }
    } else {
      // <-- Rectangular: need both length and width -->
      final lengthMm = int.tryParse(value);
      final widthMm = int.tryParse(row.widthMmController.text);
      row.isValid = (lengthMm != null && lengthMm > 0) &&
                    (widthMm != null && widthMm > 0);
    }
    notifyListeners();
  }

  void onWidthMmChanged(int index, String value) {
    if (index < 0 || index >= dimensionRows.length) return;
    final row = dimensionRows[index];
    final widthMm = int.tryParse(value);
    final lengthMm = int.tryParse(row.lengthMmController.text);
    row.isValid = (lengthMm != null && lengthMm > 0) &&
                  (widthMm != null && widthMm > 0);
    notifyListeners();
  }

  // <-- ============ Items Management ============ -->

  void addItems() {
    if (selectedProduct == null) {
      onError?.call('Please select a product');
      return;
    }

    if (sectionCtrl.text.trim().isEmpty) {
      onError?.call('Please enter a section/floor');
      return;
    }

    final validRows = dimensionRows.where((row) => row.isValid).toList();
    if (validRows.isEmpty) {
      onError?.call('Please add at least one valid dimension');
      return;
    }

    final section = sectionCtrl.text.trim();
    final newItems = <QuoteItem>[];

    for (final row in validRows) {
      final qty = int.tryParse(row.qtyController.text) ?? 1;
      final rawInput = double.tryParse(row.lengthMmController.text) ?? 0;
      final widthMm = int.tryParse(row.widthMmController.text) ?? 0;

      // <-- Resolve input to inches for round products -->
      final int resolvedInch = selectedProduct!.isRound
          ? (row.inputInMm ? (rawInput / 25.4).round() : rawInput.round())
          : 0;

      // <-- Build description -->
      final descBuffer = StringBuffer();
      descBuffer.write(selectedProduct!.displayName);

      if (selectedMaterial.isNotEmpty) {
        descBuffer.write(' [$selectedMaterial]');
      }

      if (selectedCustomizations.isNotEmpty) {
        final customText = selectedCustomizations.map((c) {
          if (c == 'powder' || c == 'acrylic') {
            final color = selectedColor ?? 'White';
            if (color == 'Custom' && customColorCtrl.text.isNotEmpty) {
              return '${getCustomizationDisplayName(c)} (${customColorCtrl.text})';
            }
            return '${getCustomizationDisplayName(c)} ($color)';
          }
          return getCustomizationDisplayName(c);
        }).join(', ');
        descBuffer.write(' + $customText');
      }

      // <-- neckSize shows inches for round, mm x mm for rectangular -->
      final neckSize = selectedProduct!.isRound
          ? '$resolvedInch"'
          : '${rawInput.toInt()}mm x ${widthMm}mm';

      // <-- Step 1: Base price from dimensions -->
      double unitPrice = _calculateUnitPrice(
        selectedProduct!.isRound ? resolvedInch : rawInput.toInt(),
        widthMm, // ← pass width here
      );
      // <-- Step 2: Flat fees (powder coat) -->
      unitPrice = _applyFlatFees(unitPrice);
      // <-- Step 3: Dealer + VAT markups -->
      unitPrice = unitPrice * _markupDealer * _markupVat;
      // <-- Step 4: Round to nearest 100 — skipped for round products -->
      if (!selectedProduct!.isRound) {
        unitPrice = _roundPrice(unitPrice);
      }

      newItems.add(QuoteItem(
        section: section,
        description: descBuffer.toString(),
        neckSize: neckSize,
        qty: qty,
        unitPrice: unitPrice,
        material: selectedMaterial,
        unit: selectedProduct!.unit,
        customizations: selectedCustomizations.toList(),
      ));
    }

    items.addAll(newItems);

    for (final row in dimensionRows) {
      row.dispose();
    }
    dimensionRows.clear();
    addDimensionRow();

    onSuccess?.call('Added ${newItems.length} item(s)');
    notifyListeners();
  }

  // <-- ============ Price Calculation ============ -->

  double _getCombinedMultiplier() {
    // <-- Use material-specific multiplier as the base -->
    double total = selectedProduct!.multiplierFor(selectedMaterial);

    for (final custom in selectedCustomizations) {
      switch (custom) {
        case 'obvd':    total += 5.5; break;
        case 'bird':    total += 1.5; break;
        case 'insect':  total += 1.5; break;
        case 'acrylic': total += 0.1; break;
        case 'radial':  total += 0.3; break;
        case 'powder':  break;
      }
    }
    return total;
  }

  double _calculateUnitPrice(int length, int width) {
    if (selectedProduct == null) return 0;

    if (selectedProduct!.isRound && selectedProduct!.roundPrices != null) {
      final roundBase = selectedProduct!.roundPrices![length] ?? selectedProduct!.basePrice;
      double customMult = 1.0;
      for (final custom in selectedCustomizations) {
        switch (custom) {
          case 'radial':  customMult += 0.3; break;
          case 'bird':    customMult += 1.5; break;
          case 'insect':  customMult += 1.5; break;
        }
      }
      return roundBase * customMult;
    }

    int effectiveLength = length;
    int effectiveWidth  = width;

    final lengthBig = length >= _minPricingDimension;
    final widthBig  = width  >= _minPricingDimension;

    if (!lengthBig && !widthBig) {
      // <-- Both small → clamp both to 250 -->
      effectiveLength = _minPricingDimension;
      effectiveWidth  = _minPricingDimension;
    } else if (lengthBig && !widthBig) {
      // <-- Length big, width small → add 50 to width -->
      effectiveWidth = width + 50;
    } else if (!lengthBig && widthBig) {
      // <-- Width big, length small → add 50 to length -->
      effectiveLength = length + 50;
    }
    // <-- Both big → use as-is, no changes -->

    return (effectiveLength * effectiveWidth / 624) * _getCombinedMultiplier();
  }

  double _applyFlatFees(double price) {
    if (selectedCustomizations.contains('powder')) return price + 500;
    return price;
  }

  double _roundPrice(double price) {
    final int priceInt = price.ceil();
    final int remainder = priceInt % 100;
    if (remainder == 0) return priceInt.toDouble();
    if (remainder <= 10) return (priceInt - remainder).toDouble();
    return (priceInt + (100 - remainder)).toDouble();
  }

  String getCustomizationDisplayName(String key) {
    switch (key) {
      case 'obvd':    return 'OBVD';
      case 'bird':    return 'Bird Design';
      case 'insect':  return 'Insect Design';
      case 'acrylic': return 'Acrylic';
      case 'radial':  return 'Radial';
      case 'powder':  return 'Powder Coat';
      default:        return key;
    }
  }

  // <-- ============ Remove Item ============ -->

  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      notifyListeners();
    }
  }

  // <-- ============ Quote Building & Saving ============ -->

  Quote buildQuote() {
    return Quote(
      id: editQuote?.id,
      refNo: refNoCtrl.text.trim(),
      date: selectedDate,
      company: companyCtrl.text.trim(),
      companyLocation: locationCtrl.text.trim(),
      attention: attentionCtrl.text.trim(),
      attentionTitle: titleCtrl.text.trim(),
      paymentTerms: paymentCtrl.text.trim(),
      projectLocation: projectCtrl.text.trim(),
      supplyDescription: supplyDescCtrl.text.trim(),
      leadtime: leadtimeCtrl.text.trim(),
      items: List.from(items),
      status: editQuote?.status ?? QuoteStatus.pending,
    );
  }

  Future<Quote?> saveQuote() async {
    if (items.isEmpty) {
      onError?.call('Please add at least one item');
      return null;
    }

    isSaving = true;
    notifyListeners();

    try {
      final quote = buildQuote();

      if (_repository.useApi) {
        final apiItems = items.map((item) => {
          'description': item.description,
          'neck_size': item.neckSize,
          'qty': item.qty,
          'unit_price': item.unitPrice,
          'material': item.material,
          'customizations': item.customizations,
          'item_code': item.description.split(' ').first,
        }).toList();

        final result = await _repository.createQuote(
          companyName: quote.company,
          companyLocation: quote.companyLocation,
          attentionName: quote.attention,
          attentionPosition: quote.attentionTitle,
          customerProject: quote.projectLocation,
          projectLocation: quote.projectLocation,
          createdBy: AuthService().currentUserId ?? 1,
          items: apiItems,
        );

        if (result['success'] != true) {
          throw Exception(result['message'] ?? 'Failed to save to server');
        }

        await _repository.saveLocal(quote);
      } else {
        await _repository.saveLocal(quote);
      }

      onSuccess?.call(editQuote != null ? 'Quote updated' : 'Quote saved');
      return quote;
    } catch (e) {
      onError?.call('Failed to save quote: $e');
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // <-- ============ Cleanup ============ -->

  @override
  void dispose() {
    refNoCtrl.dispose();
    companyCtrl.dispose();
    locationCtrl.dispose();
    attentionCtrl.dispose();
    titleCtrl.dispose();
    projectCtrl.dispose();
    supplyDescCtrl.dispose();
    paymentCtrl.dispose();
    leadtimeCtrl.dispose();
    sectionCtrl.dispose();
    customColorCtrl.dispose();
    for (final row in dimensionRows) {
      row.dispose();
    }
    super.dispose();
  }
}