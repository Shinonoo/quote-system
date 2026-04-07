import 'package:flutter/material.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/section_header.dart';
import '../add_quote_controller.dart';

class ProjectInfoSection extends StatelessWidget {
  final AddQuoteController controller;

  const ProjectInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Project Information',
      icon: Icons.construction,
      child: Column(
        children: [
          CustomTextField(
            controller: controller.projectCtrl,
            label: 'Project & Location *',
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: controller.supplyDescCtrl,
            label: 'Supply Description',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: controller.paymentCtrl,
            label: 'Payment Terms',
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: controller.leadtimeCtrl,
            label: 'Leadtime',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}