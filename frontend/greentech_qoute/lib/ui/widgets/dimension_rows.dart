import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../pages/add_quote/add_quote_controller.dart';

/// Header row — updates labels based on product type
class DimensionRowsHeader extends StatelessWidget {
  final bool isRoundProduct;

  const DimensionRowsHeader({
    super.key,
    this.isRoundProduct = false,
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
              // <-- Header changes based on product type -->
              isRoundProduct ? 'Diameter' : 'Length (mm)',
              style: TextStyle(
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
                'Width (mm)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
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
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// List of dimension rows
class DimensionRowsList extends StatelessWidget {
  final List<DimensionRowData> rows;
  final bool isRoundProduct;
  final ValueChanged<int> onRemove;
  final Function(int, String) onLengthMmChanged;
  final Function(int, String) onWidthMmChanged;
  final ValueChanged<int> onToggleInputUnit; // <-- new callback for mm/in toggle

  const DimensionRowsList({
    super.key,
    required this.rows,
    required this.isRoundProduct,
    required this.onRemove,
    required this.onLengthMmChanged,
    required this.onWidthMmChanged,
    required this.onToggleInputUnit, // <-- required
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
    if (isRoundProduct) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            // <-- mm / in toggle — no controller needed, uses callback -->
            ToggleButtons(
              isSelected: [row.inputInMm, !row.inputInMm],
              onPressed: (_) => onToggleInputUnit(index), // ✅ uses passed callback
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
                onChanged: (v) => onLengthMmChanged(index, v), // ✅ uses passed callback
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
            const SizedBox(width: 8),
            _buildRemoveButton(index),
          ],
        ),
      );
    }

    // <-- Rectangular row -->
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildNumberInput(
              controller: row.lengthMmController,
              hint: '300',
              onChanged: (v) => onLengthMmChanged(index, v), // ✅ uses passed callback
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _buildNumberInput(
              controller: row.widthMmController,
              hint: '300',
              onChanged: (v) => onWidthMmChanged(index, v), // ✅ uses passed callback
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
          const SizedBox(width: 8),
          _buildRemoveButton(index),
        ],
      ),
    );
  }

  Widget _buildRemoveButton(int index) {
    return SizedBox(
      width: 40,
      child: IconButton(
        onPressed: () => onRemove(index),
        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
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
        hintStyle: TextStyle(fontSize: 12, color: AppTheme.hintText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
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