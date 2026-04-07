import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Reusable text field widget with consistent styling
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final bool isNumber;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? prefixText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.isNumber = false,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.suffixIcon,
    this.prefixIcon,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      validator: validator,
      textInputAction: textInputAction,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ]
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        prefixText: prefixText,
      ),
    );
  }
}

/// Date picker field widget
class DatePickerField extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String label;

  const DatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.label = 'Date',
  });

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.primaryGreen,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(
            Icons.calendar_today,
            color: AppTheme.secondaryText,
          ),
        ),
        child: Text(
          _formatDate(selectedDate),
          style: AppTypography.bodyLarge,
        ),
      ),
    );
  }
}

/// Search text field with clear button
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final VoidCallback? onClear;

  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search...',
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppTheme.secondaryText),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                  onClear?.call();
                },
              )
            : null,
      ),
    );
  }
}

/// Row of two text fields
class TextFieldRow extends StatelessWidget {
  final TextEditingController controller1;
  final TextEditingController controller2;
  final String label1;
  final String label2;
  final bool isNumber1;
  final bool isNumber2;
  final double spacing;

  const TextFieldRow({
    super.key,
    required this.controller1,
    required this.controller2,
    required this.label1,
    required this.label2,
    this.isNumber1 = false,
    this.isNumber2 = false,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            controller: controller1,
            label: label1,
            isNumber: isNumber1,
          ),
        ),
        SizedBox(width: spacing),
        Expanded(
          child: CustomTextField(
            controller: controller2,
            label: label2,
            isNumber: isNumber2,
          ),
        ),
      ],
    );
  }
}
