import 'package:flutter/material.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/section_header.dart';
import '../add_quote_controller.dart';

class ClientInfoSection extends StatelessWidget {
  final AddQuoteController controller;

  const ClientInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Client Information',
      icon: Icons.business,
      child: Column(
        children: [
          CustomTextField(
            controller: controller.companyCtrl,
            label: 'Client Company *',
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: controller.locationCtrl,
            label: 'Client Location *',
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFieldRow(
            controller1: controller.attentionCtrl,
            controller2: controller.titleCtrl,
            label1: 'Attention (Name) *',
            label2: 'Title / Position *',
          ),
        ],
      ),
    );
  }
}