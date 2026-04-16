import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../pages/add_quote/add_quote_controller.dart';
import '../../models/dimension_row_data.dart';

/// Header row — updates labels based on product type
class DimensionRowsHeader extends StatelessWidget {
  final bool isRoundProduct;
  final bool isLinearSlot;

  const DimensionRowsHeader({
    super.key,
    this.isRoundProduct = false,
    this.isLinearSlot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              isRoundProduct ? 'Diameter' : 'Length (mm)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          if (!isRoundProduct) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text(
                isLinearSlot ? 'No. of Slots' : 'Width (mm)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          const Expanded(
            flex: 1,
            child: Text(
              'Qty',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 80),
        ],
      ),
    );
  }
}

/// List of dimension rows with live price preview + per-row customization
class DimensionRowsList extends StatelessWidget {
  final List<DimensionRowData> rows;
  final bool isRoundProduct;
  final bool isLinearSlot;
  final ValueChanged<int> onRemove;
  final Function(int, String) onLengthMmChanged;
  final Function(int, String) onWidthMmChanged;
  final ValueChanged<int> onToggleInputUnit;
  final void Function(int)? onCustomize;

  const DimensionRowsList({
    super.key,
    required this.rows,
    required this.isRoundProduct,
    this.isLinearSlot = false,
    required this.onRemove,
    required this.onLengthMmChanged,
    required this.onWidthMmChanged,
    required this.onToggleInputUnit,
    this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        return _buildDimensionRow(index, row);
      }).toList(),
    );
  }

  Widget _buildDimensionRow(int index, DimensionRowData row) {
    final hasCustomizations = row.customizations.isNotEmpty;
    final customCount = row.customizations.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRoundProduct)
            Row(
              children: [
                ToggleButtons(
                  isSelected: [row.inputInMm, !row.inputInMm],
                  onPressed: (_) => onToggleInputUnit(index),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('mm'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('in'),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildNumberInput(
                    controller: row.lengthMmController,
                    hint: row.inputInMm ? 'e.g. 203' : 'e.g. 8',
                    onChanged: (v) => onLengthMmChanged(index, v),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: _buildNumberInput(
                    controller: row.qtyController,
                    hint: '1',
                  ),
                ),
                const SizedBox(width: 4),
                _buildCustomizeButton(index, hasCustomizations, customCount),
                _buildRemoveButton(index),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildNumberInput(
                    controller: row.lengthMmController,
                    hint: '300',
                    onChanged: (v) => onLengthMmChanged(index, v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildNumberInput(
                    controller: row.widthMmController,
                    hint: isLinearSlot ? 'e.g. 3' : '300',
                    onChanged: (v) => onWidthMmChanged(index, v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: _buildNumberInput(
                    controller: row.qtyController,
                    hint: '1',
                  ),
                ),
                const SizedBox(width: 4),
                _buildCustomizeButton(index, hasCustomizations, customCount),
                _buildRemoveButton(index),
              ],
            ),

          if (hasCustomizations)
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: row.customizations.map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _shortLabel(c, row),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

          if (row.previewPrice > 0)
            Padding(
              padding: const EdgeInsets.only(
                top: 2,
                bottom: 6,
                left: 4,
                right: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Unit: ${_formatPrice(row.previewPrice / (int.tryParse(row.qtyController.text) ?? 1))}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  Text(
                    'Subtotal: ${_formatPrice(row.previewPrice)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildCustomizeButton(
    int index,
    bool hasCustomizations,
    int customCount,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: onCustomize != null ? () => onCustomize!(index) : null,
            icon: Icon(
              Icons.tune,
              size: 18,
              color: hasCustomizations
                  ? AppTheme.primaryGreen
                  : Colors.grey.shade400,
            ),
            tooltip: hasCustomizations
                ? '$customCount customization(s) — tap to edit'
                : 'Add customization',
          ),
        ),
        if (hasCustomizations)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$customCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _shortLabel(String key, DimensionRowData row) {
    switch (key) {
      case 'powder':
        final color = row.selectedColor ?? 'White';
        final label = color == 'Custom' && row.customColorText.isNotEmpty
            ? row.customColorText
            : color;
        return 'PC ($label)';
      case 'acrylic':
        return 'Acrylic';
      case 'obvd':
        return 'OBVD';
      case 'bird':
        return 'Bird';
      case 'insect':
        return 'Insect';
      case 'radial':
        return 'Radial';
      default:
        return key;
    }
  }

  String _formatPrice(double price) =>
      '₱${price.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'),
        (m) => '${m[1]},',
      )}';

  Widget _buildRemoveButton(int index) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () => onRemove(index),
        icon: const Icon(
          Icons.remove_circle_outline,
          color: Colors.red,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: readOnly ? AppTheme.secondaryText : AppTheme.primaryText,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: AppTheme.hintText),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        ),
        filled: true,
        fillColor: readOnly
            ? AppTheme.dividerColor.withOpacity(0.3)
            : AppTheme.surfaceColor,
      ),
      onChanged: onChanged,
    );
  }
}