import 'package:flutter/material.dart';
import '../../constants/products.dart';
import '../../../../core/theme/app_theme.dart';
import '../pages/add_quote/add_quote_controller.dart';
import '../../models/dimension_row_data.dart';

/// Bottom sheet for per-row customization.
/// Opens instantly, applies on tap — no confirmation needed.
class RowCustomizationSheet extends StatefulWidget {
  final int rowIndex;
  final Product product;
  final Set<String> initialCustomizations;
  final String? initialColor;
  final String initialCustomColorText;
  final List<String> standardColors;
  final bool isOverridden;

  final Set<String> globalCustomizations;
  final String? globalColor;
  final String globalCustomColorText;

  final void Function(
    int index,
    Set<String> customizations,
    String? color,
    String customColorText,
    bool hasOverride,
  ) onApply;

  const RowCustomizationSheet({
    super.key,
    required this.rowIndex,
    required this.product,
    required this.initialCustomizations,
    required this.initialColor,
    required this.initialCustomColorText,
    required this.standardColors,
    required this.isOverridden,
    required this.globalCustomizations,
    required this.globalColor,
    required this.globalCustomColorText,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required int rowIndex,
    required Product product,
    required DimensionRowData row,
    required List<String> standardColors,
    required Set<String> globalCustomizations,
    required String? globalColor,
    required String globalCustomColorText,
    required void Function(
      int,
      Set<String>,
      String?,
      String,
      bool,
    ) onApply,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RowCustomizationSheet(
        rowIndex: rowIndex,
        product: product,
        initialCustomizations: Set.from(row.customizations),
        initialColor: row.selectedColor,
        initialCustomColorText: row.customColorText,
        standardColors: standardColors,
        isOverridden: row.hasCustomOverride,
        globalCustomizations: globalCustomizations,
        globalColor: globalColor,
        globalCustomColorText: globalCustomColorText,
        onApply: onApply,
      ),
    );
  }

  @override
  State<RowCustomizationSheet> createState() => _RowCustomizationSheetState();
}

class _RowCustomizationSheetState extends State<RowCustomizationSheet> {
  late Set<String> _customizations;
  String? _selectedColor;
  late TextEditingController _customColorCtrl;
  late bool _isOverridden;

  bool get _needsColor =>
      _customizations.contains('powder') ||
      _customizations.contains('acrylic');

  @override
  void initState() {
    super.initState();
    _customizations = Set.from(widget.initialCustomizations);
    _selectedColor = widget.initialColor;
    _isOverridden = widget.isOverridden;
    _customColorCtrl =
        TextEditingController(text: widget.initialCustomColorText);
  }

  @override
  void dispose() {
    _customColorCtrl.dispose();
    super.dispose();
  }

  void _toggle(String key) {
    setState(() {
      _isOverridden = true;

      if (_customizations.contains(key)) {
        _customizations.remove(key);

        if (key == 'powder' || key == 'acrylic') {
          if (!_customizations.contains('powder') &&
              !_customizations.contains('acrylic')) {
            _selectedColor = null;
            _customColorCtrl.clear();
          }
        }
      } else {
        _customizations.add(key);
      }
    });
  }

  void _applyAndClose() {
    widget.onApply(
      widget.rowIndex,
      Set.from(_customizations),
      _selectedColor,
      _customColorCtrl.text,
      _isOverridden,
    );
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() {
      _isOverridden = true;
      _customizations.clear();
      _selectedColor = null;
      _customColorCtrl.clear();
    });
  }

  void _useGlobal() {
    setState(() {
      _customizations = Set.from(widget.globalCustomizations);
      _selectedColor = widget.globalColor;
      _customColorCtrl.text = widget.globalCustomColorText;
      _isOverridden = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableCustomizations = widget.product.customizations;
    final hasAny = availableCustomizations.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.tune, size: 18, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Row ${widget.rowIndex + 1} Customization',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (_isOverridden) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.4),
                      ),
                    ),
                    child: const Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (_isOverridden)
                  TextButton.icon(
                    onPressed: _useGlobal,
                    icon: const Icon(Icons.sync, size: 13),
                    label: const Text(
                      'Use global',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (_customizations.isNotEmpty)
                  TextButton(
                    onPressed: _clearAll,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Clear all',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          if (!hasAny)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No customizations available for this product.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableCustomizations.map((key) {
                  final isSelected = _customizations.contains(key);
                  return _CustomChip(
                    label: _label(key),
                    icon: _icon(key),
                    selected: isSelected,
                    onTap: () => _toggle(key),
                  );
                }).toList(),
              ),
            ),

            if (_needsColor) ...[
              const Divider(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Color',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.standardColors.map((color) {
                        final isCustom = color == 'Custom';
                        final isSelected = _selectedColor == color;
                        return _ColorChip(
                          label: color,
                          selected: isSelected,
                          onTap: () => setState(() {
                            _isOverridden = true;
                            _selectedColor = color;
                            if (!isCustom) _customColorCtrl.clear();
                          }),
                        );
                      }).toList(),
                    ),
                    if (_selectedColor == 'Custom') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customColorCtrl,
                        autofocus: true,
                        onChanged: (_) =>
                            setState(() => _isOverridden = true),
                        decoration: InputDecoration(
                          hintText: 'Enter custom color...',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyAndClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _customizations.isEmpty
                      ? 'Apply (No Customization)'
                      : 'Apply — ${_customizations.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(String key) {
    switch (key) {
      case 'obvd':
        return 'OBVD';
      case 'bird':
        return 'Bird Screen';
      case 'insect':
        return 'Insect Screen';
      case 'acrylic':
        return 'Acrylic';
      case 'radial':
        return 'Radial';
      case 'powder':
        return 'Powder Coat';
      default:
        return key;
    }
  }

  IconData _icon(String key) {
    switch (key) {
      case 'obvd':
        return Icons.speed;
      case 'bird':
        return Icons.flutter_dash;
      case 'insect':
        return Icons.bug_report;
      case 'acrylic':
        return Icons.layers;
      case 'radial':
        return Icons.rotate_right;
      case 'powder':
        return Icons.color_lens;
      default:
        return Icons.check_circle_outline;
    }
  }
}

// ─── Reusable Chips ──────────────────────────────────────────────────────────

class _CustomChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CustomChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check : icon,
              size: 15,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryGreen.withOpacity(0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? AppTheme.primaryGreen : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}