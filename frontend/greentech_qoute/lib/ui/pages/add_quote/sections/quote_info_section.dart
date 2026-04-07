import 'package:flutter/material.dart';
import '../../../widgets/custom_text_field.dart'; 
import '../../../widgets/section_header.dart';     
import '../add_quote_controller.dart';            

class QuoteInfoSection extends StatelessWidget {
  final AddQuoteController controller;

  const QuoteInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Quote Information',
      icon: Icons.receipt_long,
      child: Column(
        children: [
          CustomTextField(
            controller: controller.refNoCtrl,
            label: 'Reference No. *',
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DatePickerField(
            selectedDate: controller.selectedDate,
            onDateSelected: controller.setSelectedDate,
          ),
        ],
      ),
    );
  }
}