import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../sollume/shared/app_text_field.dart' as sollume;
import '../../sollume/core/theme/app_radius.dart';

import 'app_tap.dart';

/// Thanh tìm kiếm của Home, dùng chung cho dạng mở trang và nhập trực tiếp.
class AppSearchBar extends StatelessWidget {
  final String hintText;
  final String initialValue;
  final TextEditingController? controller;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final Key? fieldKey;
  final int? maxLength;
  final EdgeInsetsGeometry padding;
  final String? actionName;
  const AppSearchBar({
    super.key,
    required this.hintText,
    this.initialValue = '',
    this.controller,
    this.onClear,
    this.onSubmitted,
    this.onChanged,
    this.onTap,
    this.fieldKey,
    this.maxLength,
    this.padding = EdgeInsets.zero,
    this.actionName,
  });

  @override
  Widget build(BuildContext context) {
    final field = sollume.AppTextField(
      key: fieldKey,
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      hintText: hintText,
      readOnly: onChanged == null,
      onChanged: onChanged,
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      onSubmitted: (_) {
        FocusScope.of(context).unfocus();
        onSubmitted?.call();
      },
      radius: AppRadius.search,
      showFocusedBorder: false,
      textInputAction: TextInputAction.search,
      prefixIcon: const Icon(PhosphorIconsBold.magnifyingGlass, size: 20),
      prefixIconPadding: const EdgeInsetsDirectional.only(start: 14, end: 4),
      suffixIcon: onClear == null
          ? null
          : IconButton(
              tooltip: 'Xóa tìm kiếm',
              onPressed: onClear,
              icon: const Icon(PhosphorIconsBold.x, size: 20),
            ),
    );
    return Padding(
      padding: padding,
      child: onChanged == null
          ? AppTap(
              actionName: actionName,
              onTap: onTap,
              child: ExcludeFocus(child: IgnorePointer(child: field)),
            )
          : field,
    );
  }
}
