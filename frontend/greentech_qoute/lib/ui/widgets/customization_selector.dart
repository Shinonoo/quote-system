import 'package:flutter/material.dart';
import '../../core/constants/products.dart';
import '../../core/theme/app_theme.dart';

/// Widget for selecting product customizations
class CustomizationSelector extends StatelessWidget {
  final List<String> availableCustomizations;
  final Set<String> selectedCustomizations;
  final ValueChanged<String> onCustomizationToggled;

  const CustomizationSelector({
    super.key,
    required this.availableCustomizations,
    required this.selectedCustomizations,
    required this.onCustomizationToggled,
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
            'Customizations',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableCustomizations.map((customization) {
              final isSelected = selectedCustomizations.contains(customization);
              final displayName = getCustomizationDisplayName(customization);
              final info = getCustomizationInfo(customization);
              
              return _buildCustomizationChip(
                customization: customization,
                displayName: displayName,
                info: info,
                isSelected: isSelected,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationChip({
    required String customization,
    required String displayName,
    required String info,
    required bool isSelected,
  }) {
    return Tooltip(
      message: info.isNotEmpty ? 'Price: $info' : 'Toggle customization',
      child: FilterChip(
        label: Text(displayName),
        selected: isSelected,
        onSelected: (_) => onCustomizationToggled(customization),
        backgroundColor: AppTheme.dividerColor.withOpacity(0.5),
        selectedColor: AppTheme.accentGreen.withOpacity(0.3),
        checkmarkColor: AppTheme.primaryGreen,
        labelStyle: TextStyle(
          fontSize: 12,
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }
}
