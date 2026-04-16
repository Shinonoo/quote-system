import 'package:flutter/material.dart';
import '../../../../models/quote_item.dart'; 
import '../../../widgets/item_list_tile.dart';
import '../../../../../../shared/widgets/section_header.dart';
import '../add_quote_controller.dart';

class ItemsPreviewSection extends StatelessWidget {
  final AddQuoteController controller;

  const ItemsPreviewSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final totalQty = controller.items.fold<int>(0, (sum, item) => sum + item.qty);
    final totalAmount = controller.items.fold<double>(0.0, (sum, item) => sum + item.total);

    return SectionCard(
      title: 'Items Preview',
      icon: Icons.preview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildGroupedItems(),
          const Divider(height: 32),
          QuoteTotalCard(
            itemCount: controller.items.length,
            totalQty: totalQty,
            totalAmount: totalAmount,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedItems() {
    final grouped = <String, List<QuoteItem>>{};

    for (final item in controller.items) {
      grouped.putIfAbsent(item.section, () => <QuoteItem>[]).add(item);
    }

    final widgets = <Widget>[];
    int globalIndex = 0;

    for (final entry in grouped.entries) {
      final sectionItems = entry.value;
      final sectionTotal = sectionItems.fold<double>(0.0, (sum, item) => sum + item.total);

      widgets.add(ItemSectionHeader(
        section: entry.key,
        sectionTotal: sectionTotal,
        itemCount: sectionItems.length,
      ));
      widgets.add(const SizedBox(height: 8));

      for (final item in sectionItems) {
        widgets.add(
          ItemListTile(
            item: item,
            index: globalIndex++,
            showSection: false,
            onRemove: () {
              final index = controller.items.indexOf(item);
              if (index != -1) controller.removeItem(index);
            },
          ),
        );
      }

      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }
}