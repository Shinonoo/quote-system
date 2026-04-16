import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../constants/products.dart';
import '../../../constants/actuators.dart';
import '../../../models/quote.dart';
import '../../../models/quote_item.dart';
import '../../../models/dimension_row_data.dart';      // ← extracted
import '../../../repositories/quote_repository.dart';
import '../../../services/actuator_service.dart';
import '../../../services/pricing_service.dart';       // ← extracted
import '../../../../auth/services/auth_service.dart';


class AddQuoteController extends ChangeNotifier {

  // ── Constructor Arguments ─────────────────────────────────
  final Quote?                  editQuote;
  final void Function(String)?  onError;
  final void Function(String)?  onSuccess;

  // ── Text Controllers ──────────────────────────────────────
  final TextEditingController refNoCtrl       = TextEditingController();
  final TextEditingController companyCtrl     = TextEditingController();
  final TextEditingController locationCtrl    = TextEditingController();
  final TextEditingController attentionCtrl   = TextEditingController();
  final TextEditingController titleCtrl       = TextEditingController();
  final TextEditingController projectCtrl     = TextEditingController();
  final TextEditingController supplyDescCtrl  = TextEditingController();
  final TextEditingController paymentCtrl     = TextEditingController();
  final TextEditingController leadtimeCtrl    = TextEditingController();
  final TextEditingController sectionCtrl     = TextEditingController();
  final TextEditingController customColorCtrl = TextEditingController();

  // ── State ─────────────────────────────────────────────────
  DateTime               selectedDate           = DateTime.now();
  Product?               selectedProduct;
  String                 selectedMaterial       = '';
  Set<String>            selectedCustomizations = {};
  String?                selectedColor;
  List<QuoteItem>        items                  = [];
  List<DimensionRowData> dimensionRows          = [];
  ActuatorSection?       selectedActuatorSection;
  bool                   isSaving               = false;

  final List<String> standardColors = [
    'White', 'Black', 'Gray', 'Ivory', 'Beige', 'Custom',
  ];

  final QuoteRepository _repository = QuoteRepository();

  AddQuoteController({
    this.editQuote,
    this.onError,
    this.onSuccess,
  }) {
    _initialize();
  }


  // ============ Getters ============


  bool get productHasActuator => selectedProduct?.hasActuator ?? false;


  // ============ Initialization ============


  void _initialize() {
    supplyDescCtrl.text = AppConstants.defaultSupplyDescription;
    paymentCtrl.text    = AppConstants.defaultPaymentTerms;
    leadtimeCtrl.text   = AppConstants.defaultLeadtime;

    if (editQuote != null) {
      _populateFromEditQuote();
    } else {
      refNoCtrl.text = '${AppConstants.refNoPrefix}${_generateRefSuffix()}';
    }

    addDimensionRow();
  }

  void _populateFromEditQuote() {
    final q             = editQuote!;
    refNoCtrl.text      = q.refNo;
    selectedDate        = q.date;
    companyCtrl.text    = q.company;
    locationCtrl.text   = q.companyLocation;
    attentionCtrl.text  = q.attention;
    titleCtrl.text      = q.attentionTitle;
    projectCtrl.text    = q.projectLocation;
    supplyDescCtrl.text = q.supplyDescription;
    paymentCtrl.text    = q.paymentTerms;
    leadtimeCtrl.text   = q.leadtime;
    items               = List.from(q.items);
  }

  String _generateRefSuffix() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '-${now.millisecond.toString().padLeft(3, '0')}';
  }


  // ============ Setters ============


  void setSelectedDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void setSelectedProduct(Product? product) {
    selectedProduct         = product;
    selectedMaterial        = product?.materials.first ?? '';
    selectedActuatorSection = null;
    selectedCustomizations  = {};
    selectedColor           = null;
    customColorCtrl.clear();
    for (final row in dimensionRows) {
      row.customizations    = {};
      row.selectedColor     = null;
      row.customColorText   = '';
      row.hasCustomOverride = false;
    }
    _refreshAllPreviews();
    notifyListeners();
  }

  void setSelectedMaterial(String material) {
    selectedMaterial = material;
    _refreshAllPreviews();
    notifyListeners();
  }

  void setActuatorSection(ActuatorSection? section) {
    selectedActuatorSection = section;
    _refreshAllPreviews();
    notifyListeners();
  }

  void toggleCustomization(String customization) {
    if (selectedCustomizations.contains(customization)) {
      selectedCustomizations.remove(customization);
      if (customization == 'powder' || customization == 'acrylic') {
        final hasColorCustom = selectedCustomizations.contains('powder') ||
                               selectedCustomizations.contains('acrylic');
        if (!hasColorCustom) {
          selectedColor = null;
          customColorCtrl.clear();
        }
      }
    } else {
      selectedCustomizations.add(customization);
    }
    _propagateGlobalToRows();
    notifyListeners();
  }

  void setSelectedColor(String? color) {
    selectedColor = color;
    if (color != 'Custom') customColorCtrl.clear();
    _propagateGlobalToRows();
    notifyListeners();
  }

  void updateRowCustomizations(
    int index,
    Set<String> customizations,
    String? color,
    String customColorText,
    bool hasOverride,
  ) {
    if (index < 0 || index >= dimensionRows.length) return;
    final row             = dimensionRows[index];
    row.customizations    = customizations;
    row.selectedColor     = color;
    row.customColorText   = customColorText;
    row.hasCustomOverride = hasOverride;
    _updateRowPreview(index);
    notifyListeners();
  }


  // ============ Dimension Rows ============


  void addDimensionRow() {
    final row = DimensionRowData(
      customizations:    Set.from(selectedCustomizations),
      selectedColor:     selectedColor,
      customColorText:   customColorCtrl.text,
      hasCustomOverride: false,
    );
    row.qtyController.addListener(() {
      final index = dimensionRows.indexOf(row);
      if (index != -1) _updateRowPreview(index);
    });
    dimensionRows.add(row);
    notifyListeners();
  }

  void removeDimensionRow(int index) {
    if (index < 0 || index >= dimensionRows.length) return;
    dimensionRows[index].dispose();
    dimensionRows.removeAt(index);
    notifyListeners();
  }

  void toggleInputUnit(int index) {
    if (index < 0 || index >= dimensionRows.length) return;
    final row             = dimensionRows[index];
    row.inputInMm         = !row.inputInMm;
    row.isValid           = false;
    row.previewPrice      = 0.0;
    row.actuatorSelection = null;
    row.lengthMmController.clear();
    notifyListeners();
  }

  void onLengthMmChanged(int index, String value) {
    if (index < 0 || index >= dimensionRows.length) return;
    final row   = dimensionRows[index];
    final input = double.tryParse(value);

    if (selectedProduct?.isRound == true) {
      if (input == null || input <= 0) {
        row.isValid = false;
      } else {
        final inch  = row.inputInMm ? (input / 25.4).round() : input.round();
        row.isValid = selectedProduct!.roundPrices!.containsKey(inch);
      }
    } else {
      final lengthMm = int.tryParse(value);
      final widthMm  = int.tryParse(row.widthMmController.text);
      row.isValid = (lengthMm != null && lengthMm > 0) &&
                    (widthMm  != null && widthMm  > 0);
    }

    _updateRowPreview(index);
    notifyListeners();
  }

  void onWidthMmChanged(int index, String value) {
    if (index < 0 || index >= dimensionRows.length) return;
    final row      = dimensionRows[index];
    final widthMm  = int.tryParse(value);
    final lengthMm = int.tryParse(row.lengthMmController.text);
    row.isValid = (lengthMm != null && lengthMm > 0) &&
                  (widthMm  != null && widthMm  > 0);
    _updateRowPreview(index);
    notifyListeners();
  }


  // ============ Live Price Preview ============


  void _updateRowPreview(int index) {
    if (index < 0 || index >= dimensionRows.length) return;
    if (selectedProduct == null) return;

    final row = dimensionRows[index];

    if (!row.isValid) {
      row.previewPrice      = 0.0;
      row.actuatorSelection = null;
      notifyListeners();
      return;
    }

    final rawInput = double.tryParse(row.lengthMmController.text) ?? 0;
    final widthRaw = int.tryParse(row.widthMmController.text) ?? 0;
    final qty      = int.tryParse(row.qtyController.text) ?? 1;

    final int resolvedInch = selectedProduct!.isRound
        ? (row.inputInMm ? (rawInput / 25.4).round() : rawInput.round())
        : 0;

    double unitPrice = PricingService.calculateUnitPrice(
      selectedProduct,
      selectedMaterial,
      selectedProduct!.isRound ? resolvedInch : rawInput.toInt(),
      widthRaw,
      row.customizations,
    );
    unitPrice = PricingService.applyFlatFees(unitPrice, row.customizations);

    if (selectedProduct!.hasFusibleLink) {
      unitPrice += PricingService.calculateFusibleLinkCount(rawInput.toInt(), widthRaw)
          * PricingService.fusibleLinkCost;
    }

    unitPrice = unitPrice * PricingService.markupDealer * PricingService.markupVat;

    if (selectedProduct!.isImported) unitPrice *= PricingService.markupImported;

    unitPrice        = PricingService.roundPrice(unitPrice);
    row.previewPrice = unitPrice * qty;

    row.actuatorSelection = (productHasActuator && selectedActuatorSection != null)
        ? ActuatorService.select(
            section:  selectedActuatorSection!,
            lengthMm: rawInput.toInt(),
            widthMm:  widthRaw,
          )
        : null;

    notifyListeners();
  }

  void _refreshAllPreviews() {
    for (int i = 0; i < dimensionRows.length; i++) {
      _updateRowPreview(i);
    }
  }

  void _propagateGlobalToRows() {
    for (int i = 0; i < dimensionRows.length; i++) {
      final row = dimensionRows[i];
      if (!row.hasCustomOverride) {
        row.customizations  = Set.from(selectedCustomizations);
        row.selectedColor   = selectedColor;
        row.customColorText = customColorCtrl.text;
        _updateRowPreview(i);
      }
    }
  }


  // ============ Items Management ============


  void addItems() {
    if (selectedProduct == null) {
      onError?.call('Please select a product');
      return;
    }
    if (sectionCtrl.text.trim().isEmpty) {
      onError?.call('Please enter a section/floor');
      return;
    }

    final validRows = dimensionRows.where((r) => r.isValid).toList();
    if (validRows.isEmpty) {
      onError?.call('Please add at least one valid dimension');
      return;
    }
    if (productHasActuator && selectedActuatorSection == null) {
      onError?.call('Please select an actuator type');
      return;
    }

    final bool isLinearSlot =
        selectedProduct!.displayName.toLowerCase().contains('linear slot');
    final section  = sectionCtrl.text.trim();
    final newItems = <QuoteItem>[];

    for (final row in validRows) {
      final qty      = int.tryParse(row.qtyController.text) ?? 1;
      final rawInput = double.tryParse(row.lengthMmController.text) ?? 0;
      final widthRaw = int.tryParse(row.widthMmController.text) ?? 0;

      final int resolvedInch = selectedProduct!.isRound
          ? (row.inputInMm ? (rawInput / 25.4).round() : rawInput.round())
          : 0;

      // ── Description ───────────────────────────────────────
      final descBuffer = StringBuffer()..write(selectedProduct!.displayName);
      if (selectedMaterial.isNotEmpty) {
        descBuffer.write(' [$selectedMaterial]');
      }
      if (row.customizations.isNotEmpty) {
        final customText = row.customizations.map((c) {
          if (c == 'powder' || c == 'acrylic') {
            final color = row.selectedColor ?? 'White';
            if (color == 'Custom' && row.customColorText.isNotEmpty) {
              return '${getCustomizationDisplayName(c)} (${row.customColorText})';
            }
            return '${getCustomizationDisplayName(c)} ($color)';
          }
          return getCustomizationDisplayName(c);
        }).join(', ');
        descBuffer.write(' + $customText');
      }

      // ── Neck size ─────────────────────────────────────────
      final neckSize = selectedProduct!.isRound
          ? '$resolvedInch"'
          : isLinearSlot
              ? '${rawInput.toInt()}mm x $widthRaw slots'
              : '${rawInput.toInt()}mm x ${widthRaw}mm';

      // ── Price ─────────────────────────────────────────────
      double unitPrice = PricingService.calculateUnitPrice(
        selectedProduct,
        selectedMaterial,
        selectedProduct!.isRound ? resolvedInch : rawInput.toInt(),
        widthRaw,
        row.customizations,
      );
      unitPrice = PricingService.applyFlatFees(unitPrice, row.customizations);

      if (selectedProduct!.hasFusibleLink) {
        unitPrice += PricingService.calculateFusibleLinkCount(rawInput.toInt(), widthRaw)
            * PricingService.fusibleLinkCost;
      }

      unitPrice = unitPrice * PricingService.markupDealer * PricingService.markupVat;

      if (selectedProduct!.isImported) unitPrice *= PricingService.markupImported;

      unitPrice = PricingService.roundPrice(unitPrice);

      // ── Damper line item ──────────────────────────────────
      newItems.add(QuoteItem(
        section:        section,
        description:    descBuffer.toString(),
        neckSize:       neckSize,
        qty:            qty,
        unitPrice:      unitPrice,
        material:       selectedMaterial,
        unit:           selectedProduct!.unit,
        customizations: row.customizations.toList(),
      ));

      // ── Actuator line item ────────────────────────────────
      if (row.actuatorSelection != null) {
        final actuator = row.actuatorSelection!;
        newItems.add(QuoteItem(
          section:        section,
          description:    'BELIMO ${actuator.label} [${selectedActuatorSection!.label}]',
          neckSize:       '${actuator.nmRequired.toStringAsFixed(2)} Nm → ${actuator.nmProvided.toStringAsFixed(1)} Nm',
          qty:            qty * actuator.quantity,
          unitPrice:      actuator.unitPrice,
          material:       '',
          unit:           'pcs',
          customizations: const [],
        ));
      }
    }

    items.addAll(newItems);
    for (final row in dimensionRows) row.dispose();
    dimensionRows.clear();
    addDimensionRow();

    onSuccess?.call('Added ${newItems.length} item(s)');
    notifyListeners();
  }

  void removeItem(int index) {
    if (index < 0 || index >= items.length) return;
    items.removeAt(index);
    notifyListeners();
  }


  // ============ Display Helpers ============


  String getCustomizationDisplayName(String key) {
    switch (key) {
      case 'obvd':    return 'OBVD';
      case 'bird':    return 'Bird Screen';
      case 'insect':  return 'Insect Screen';
      case 'acrylic': return 'Acrylic';
      case 'radial':  return 'Radial';
      case 'powder':  return 'Powder Coat';
      default:        return key;
    }
  }


  // ============ Quote Building & Saving ============


  Quote buildQuote() {
    return Quote(
      id:                editQuote?.id,
      refNo:             refNoCtrl.text.trim(),
      date:              selectedDate,
      company:           companyCtrl.text.trim(),
      companyLocation:   locationCtrl.text.trim(),
      attention:         attentionCtrl.text.trim(),
      attentionTitle:    titleCtrl.text.trim(),
      paymentTerms:      paymentCtrl.text.trim(),
      projectLocation:   projectCtrl.text.trim(),
      supplyDescription: supplyDescCtrl.text.trim(),
      leadtime:          leadtimeCtrl.text.trim(),
      items:             List.from(items),
      status:            editQuote?.status ?? QuoteStatus.pending,
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
        final apiItems = items.map((item) {
          final isRound = item.neckSize.contains('"');
          return {
            'description':    item.description,
            'neck_size':      isRound ? '0mm x 0mm' : item.neckSize,
            'inch_size':      isRound
                ? int.tryParse(item.neckSize.replaceAll('"', '').trim()) ?? 0
                : null,
            'qty':            item.qty,
            'unit_price':     item.unitPrice,
            'material':       item.material,
            'customizations': item.customizations,
            'item_code':      item.description.split(' ').first,
          };
        }).toList();

        final result = await _repository.createQuote(
          companyName:       quote.company,
          companyLocation:   quote.companyLocation,
          attentionName:     quote.attention,
          attentionPosition: quote.attentionTitle,
          customerProject:   projectCtrl.text.trim(),
          projectLocation:   quote.projectLocation,
          createdBy:         AuthService().currentUserId ?? 1,
          items:             apiItems,
        );

        if (result['success'] != true) {
          throw Exception(result['message'] ?? 'Failed to save to server');
        }

        final serverRefNo = result['ref_no']?.toString()
            ?? result['reference_no']?.toString();
        final savedQuote  = serverRefNo != null
            ? quote.copyWith(
                id:    result['quotation_id']?.toString() ?? quote.id,
                refNo: serverRefNo,
              )
            : quote;

        await _repository.saveLocal(savedQuote);
        onSuccess?.call(editQuote != null
            ? 'Quote updated (${savedQuote.refNo})'
            : 'Quote saved (${savedQuote.refNo})');
        return savedQuote;

      } else {
        await _repository.saveLocal(quote);
        onSuccess?.call(editQuote != null ? 'Quote updated' : 'Quote saved (offline)');
        return quote;
      }
    } catch (e) {
      onError?.call('Failed to save quote: $e');
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }


  // ============ Cleanup ============


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
    for (final row in dimensionRows) row.dispose();
    super.dispose();
  }
}