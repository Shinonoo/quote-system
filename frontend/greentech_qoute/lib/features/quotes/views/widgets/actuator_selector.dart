import 'package:flutter/material.dart';
import '../../constants/actuators.dart';
import '../../services/actuator_service.dart';
import '../pages/add_quote/add_quote_controller.dart';
import '../../../../core/theme/app_theme.dart';

class ActuatorSelector extends StatelessWidget {
  final AddQuoteController controller;

  const ActuatorSelector({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!controller.productHasActuator) return const SizedBox.shrink();

    final availableSections = ActuatorData.sectionsFor(
      controller.selectedProduct!.displayName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // ── Section dropdown ───────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ActuatorSection>(
              value: controller.selectedActuatorSection,
              hint: const Text('Select Actuator Type'),
              isExpanded: true,
              items: availableSections.map((section) {
                return DropdownMenuItem(
                  value: section,
                  child: Text(section.label, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: controller.setActuatorSection,
            ),
          ),
        ),

        // ── Per-row actuator preview ───────────────────────
        if (controller.selectedActuatorSection != null) ...[
          const SizedBox(height: 8),
          ...controller.dimensionRows.asMap().entries.map((entry) {
            final row = entry.value;
            if (!row.isValid || row.actuatorSelection == null) {
              return const SizedBox.shrink();
            }
            final a = row.actuatorSelection!;
            return _ActuatorPreviewCard(selection: a);
          }),
        ],
      ],
    );
  }
}

class _ActuatorPreviewCard extends StatelessWidget {
  final ActuatorSelection selection;

  const _ActuatorPreviewCard({required this.selection});

  @override
  Widget build(BuildContext context) {
    final isMultiple = selection.quantity > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.06),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, size: 16, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      selection.model.model,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (isMultiple) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '× ${selection.quantity} units',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${selection.nmRequired.toStringAsFixed(2)} Nm required → ${selection.nmProvided.toStringAsFixed(1)} Nm provided',
                  style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                ),
              ],
            ),
          ),
          Text(
            '₱${_fmt(selection.totalPrice)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double price) => price.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}