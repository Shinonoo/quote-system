import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../models/quote_item.dart';

/// Widget for displaying a quote item in a list
class ItemListTile extends StatelessWidget {
  final QuoteItem item;
  final int index;
  final VoidCallback? onRemove;
  final bool showSection;

  const ItemListTile({
    super.key,
    required this.item,
    required this.index,
    this.onRemove,
    this.showSection = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Index number
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      children: [
                        if (showSection && item.section.isNotEmpty)
                          _buildTag(
                            Icons.location_on_outlined,
                            item.section,
                          ),
                        if (item.neckSize.isNotEmpty)
                          _buildTag(
                            Icons.straighten,
                            item.neckSize,
                          ),
                        if (item.material != null)
                          _buildTag(
                            Icons.construction_outlined,
                            item.material == 'AL' ? 'Aluminum' : 'Galvanized Iron',
                          ),
                        _buildTag(
                          Icons.inventory_2_outlined,
                          '${item.qty} ${item.unit}',
                        ),
                      ],
                    ),
                    if (item.customizations.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: item.customizations.map((c) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
                            ),
                            child: Text(
                              c.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              // Remove button
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onRemove,
                  splashRadius: 20,
                ),
            ],
          ),
          const Divider(height: 16),
          // Price row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Unit: ${item.unitPrice.asCurrencyWithSymbol}',
                style: AppTypography.bodySmall,
              ),
              Text(
                'Total: ${item.total.asCurrencyWithSymbol}',
                style: AppTypography.currencyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: AppTheme.secondaryText,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }
}

/// Section header for grouped items
class ItemSectionHeader extends StatelessWidget {
  final String section;
  final double sectionTotal;
  final int itemCount;

  const ItemSectionHeader({
    super.key,
    required this.section,
    required this.sectionTotal,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            width: 4,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.layers,
                size: 16,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                section,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$itemCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          Text(
            sectionTotal.asCurrencyWithSymbol,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary card for total amounts
class QuoteTotalCard extends StatelessWidget {
  final int itemCount;
  final int totalQty;
  final double totalAmount;

  const QuoteTotalCard({
    super.key,
    required this.itemCount,
    required this.totalQty,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat(
                'Items',
                '$itemCount',
                Icons.inventory_2,
              ),
              _buildDivider(),
              _buildStat(
                'Quantity',
                '$totalQty',
                Icons.format_list_numbered,
              ),
              _buildDivider(),
              _buildStat(
                'Total',
                totalAmount.asCurrency,
                Icons.payments,
                valueStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon,
      {TextStyle? valueStyle}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white24,
    );
  }
}
