import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../shared/widgets/custom_text_field.dart';
import '../../../widgets/customization_selector.dart';
import '../../../widgets/color_selector.dart';
import '../../../widgets/dimension_rows.dart';
import '../../../widgets/product_autocomplete.dart';
import '../../../widgets/row_customization_sheet.dart';
import '../../../../../../shared/widgets/section_header.dart';
import '../../../widgets/actuator_selector.dart';
import '../add_quote_controller.dart';

class AddItemsSection extends StatelessWidget {
  final AddQuoteController controller;

  const AddItemsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final selectedProduct = controller.selectedProduct;
    final bool isRound    = selectedProduct?.isRound == true;
    final bool isLinearSlot =
        selectedProduct?.displayName.toLowerCase().contains('linear slot') ??
            false;

    // ── Global customization visibility ───────────────────
    final bool showCustomizations =
        selectedProduct != null &&
        selectedProduct.customizations.isNotEmpty;

    final bool showColorPicker =
        showCustomizations &&
        (controller.selectedCustomizations.contains('powder') ||
            controller.selectedCustomizations.contains('acrylic'));

    return SectionCard(
      title: 'Add Items',
      icon: Icons.add_shopping_cart,
      child: Column(
        children: [
          // ── Section / Floor ──────────────────────────────
          CustomTextField(
            controller: controller.sectionCtrl,
            label: 'Section / Floor (e.g. GROUND FLOOR) *',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),

          // ── Product Selector ─────────────────────────────
          ProductAutocomplete(
            selectedProduct: selectedProduct,
            onSelected: controller.setSelectedProduct,
          ),
          const SizedBox(height: 12),

          // ── Material Dropdown (if multiple materials) ────
          if (selectedProduct != null && selectedProduct.materials.length > 1)
            _buildMaterialDropdown(controller),

          // ── Actuator Type Selector ───────────────────────
          if (selectedProduct != null)
            ActuatorSelector(controller: controller),

          // ── Global Customization Selector ─────────────────
          if (showCustomizations) ...[
            const SizedBox(height: 8),
            CustomizationSelector(
              availableCustomizations: selectedProduct.customizations,
              selectedCustomizations:  controller.selectedCustomizations,
              onCustomizationToggled:  controller.toggleCustomization,
            ),
          ],

          // ── Global Color Picker ───────────────────────────
          if (showColorPicker) ...[
            const SizedBox(height: 4),
            ColorSelector(
              standardColors:        controller.standardColors,
              selectedColor:         controller.selectedColor,
              customColorController: controller.customColorCtrl,
              onColorSelected:       controller.setSelectedColor,
            ),
          ],

          const SizedBox(height: 4),

          // ── Dimension Rows Header ────────────────────────
          DimensionRowsHeader(
            isRoundProduct: isRound,
            isLinearSlot:   isLinearSlot,
          ),

          // ── Dimension Rows List ──────────────────────────
          DimensionRowsList(
            rows:              controller.dimensionRows,
            isRoundProduct:    isRound,
            isLinearSlot:      isLinearSlot,
            onRemove:          controller.removeDimensionRow,
            onLengthMmChanged: controller.onLengthMmChanged,
            onWidthMmChanged:  controller.onWidthMmChanged,
            onToggleInputUnit: controller.toggleInputUnit,
            onCustomize: selectedProduct != null
                ? (index) => RowCustomizationSheet.show(
                      context:               context,
                      rowIndex:              index,
                      product:               selectedProduct,
                      row:                   controller.dimensionRows[index],
                      standardColors:        controller.standardColors,
                      globalCustomizations:  controller.selectedCustomizations,
                      globalColor:           controller.selectedColor,
                      globalCustomColorText: controller.customColorCtrl.text,
                      onApply: (i, customizations, color, customColorText, hasOverride) =>
                          controller.updateRowCustomizations(
                            i,
                            customizations,
                            color,
                            customColorText,
                            hasOverride,
                          ),
                    )
                : null,
          ),

          const SizedBox(height: 8),
          _buildAddDimensionButton(controller),
          const SizedBox(height: 16),
          _buildAddItemsButton(controller),
        ],
      ),
    );
  }

  Widget _buildMaterialDropdown(AddQuoteController controller) {
    final materials = controller.selectedProduct?.materials ?? const <String>[];
    if (materials.isEmpty) return const SizedBox.shrink();

    final selectedValue = materials.contains(controller.selectedMaterial)
        ? controller.selectedMaterial
        : materials.first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value:      selectedValue,
          hint:       const Text('Select Material'),
          isExpanded: true,
          items: materials.map((m) {
            return DropdownMenuItem<String>(
              value: m,
              child: Text(_materialLabel(m)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) controller.setSelectedMaterial(value);
          },
        ),
      ),
    );
  }

  String _materialLabel(String material) {
    switch (material) {
      case 'AL': return 'AL - Aluminum';
      case 'GI': return 'GI - Galvanized Iron';
      default:   return material;
    }
  }

  Widget _buildAddDimensionButton(AddQuoteController controller) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: controller.addDimensionRow,
            icon:  const Icon(Icons.add, size: 18),
            label: Text(
                '+ Add Dimension (${controller.dimensionRows.length})'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: BorderSide(color: AppTheme.primaryGreen),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddItemsButton(AddQuoteController controller) {
    final validCount =
        controller.dimensionRows.where((r) => r.isValid).length;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: controller.addItems,
        icon:  const Icon(Icons.add_shopping_cart),
        label: Text('Add $validCount Item(s)'),
      ),
    );
  }
}