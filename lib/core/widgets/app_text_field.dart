import '../../sollume/shared/app_text_field.dart' as sollume;

import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TextFormField tự sở hữu controller nội bộ; dữ liệu nghiệp vụ ở Cubit.
class AppTextField extends StatelessWidget {
  final String fieldId;
  final String initialValue;
  final String hint;
  final String? label;
  final String? error;
  final ValueChanged<String> onChanged;
  final int maxLength;
  final int minLines;
  final int maxLines;
  final bool numeric;
  final bool decimal;
  final bool enabled;
  final bool showCounter;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.fieldId,
    required this.initialValue,
    required this.hint,
    required this.onChanged,
    required this.maxLength,
    this.label,
    this.error,
    this.minLines = 1,
    this.maxLines = 1,
    this.numeric = false,
    this.decimal = false,
    this.enabled = true,
    this.showCounter = true,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label != null) ...[
        Text(label!, style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
      ],
      sollume.AppTextField(
        key: ValueKey(fieldId),
        initialValue: initialValue,
        onChanged: onChanged,
        enabled: enabled,
        minLines: minLines,
        maxLines: maxLines,
        maxLength: showCounter ? maxLength : null,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : numeric
            ? TextInputType.number
            : maxLines > 1
            ? TextInputType.multiline
            : TextInputType.text,
        textCapitalization: numeric || decimal
            ? TextCapitalization.none
            : TextCapitalization.sentences,
        inputFormatters: [
          if (!showCounter) LengthLimitingTextInputFormatter(maxLength),
          if (inputFormatters != null)
            ...inputFormatters!
          else if (decimal)
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
          else if (numeric)
            FilteringTextInputFormatter.digitsOnly,
        ],
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        hintText: hint,
        errorText: error,
      ),
    ],
  );
}
