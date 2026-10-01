import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// Dropdown with the label above it, matching [AppTextField].
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.hint,
    this.validator,
  });

  final String label;
  final List<T> items;
  final String Function(T) itemLabel;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final bool required;
  final String? hint;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(text: label, children: [
            if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.danger)),
          ]),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        DropdownButtonFormField<T>(
          initialValue: items.contains(value) ? value : null,
          isExpanded: true,
          hint: hint == null ? null : Text(hint!),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onChanged,
          validator: validator ?? (required ? (v) => v == null ? '$label is required' : null : null),
          borderRadius: AppRadius.mdAll,
        ),
      ],
    );
  }
}
