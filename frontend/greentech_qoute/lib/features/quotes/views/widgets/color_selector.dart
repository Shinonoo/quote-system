import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/custom_text_field.dart';

/// Widget for selecting powder coating color
class ColorSelector extends StatelessWidget {
  final List<String> standardColors;
  final String? selectedColor;
  final TextEditingController customColorController;
  final ValueChanged<String?> onColorSelected;

  const ColorSelector({
    super.key,
    required this.standardColors,
    required this.selectedColor,
    required this.customColorController,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: standardColors.map((color) {
              return _buildColorChip(color);
            }).toList(),
          ),
          if (selectedColor == 'Custom') ...[
            const SizedBox(height: 12),
            CustomTextField(
              controller: customColorController,
              label: 'Custom Color Name *',
              hint: 'e.g., RAL 9010',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColorChip(String color) {
    final isSelected = selectedColor == color;
    final colorValue = _getColorValue(color);
    
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (colorValue != null) ...[
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colorValue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color == 'White' ? AppTheme.dividerColor : Colors.transparent,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(color),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onColorSelected(color),
      backgroundColor: AppTheme.surfaceColor,
      selectedColor: AppTheme.accentGreen.withOpacity(0.3),
      labelStyle: TextStyle(
        fontSize: 13,
        color: isSelected ? AppTheme.primaryGreen : AppTheme.primaryText,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryGreen : AppTheme.dividerColor,
        width: isSelected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Color? _getColorValue(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black87;
      case 'gray':
        return Colors.grey[600];
      case 'ivory':
        return const Color(0xFFFFFCE6);
      case 'beige':
        return const Color(0xFFF5F5DC);
      default:
        return null;
    }
  }
}
