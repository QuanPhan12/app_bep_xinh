import 'dart:async';

import 'package:flutter/material.dart';

import '../dimensions/app_size.dart';
import '../text_styles/app_text_styles.dart';
import 'app_tap.dart';

/// Nút chữ tách từ hành động cạnh tiêu đề mục của Home.
class AppTextAction extends StatelessWidget {
  final String label;
  final FutureOr<void> Function()? onTap;
  final String? actionName;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool allowConcurrent;
  final EdgeInsetsGeometry padding;
  const AppTextAction({
    super.key,
    required this.label,
    this.onTap,
    this.actionName,
    this.leadingIcon,
    this.trailingIcon,
    this.allowConcurrent = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: AppTap(
      actionName: actionName,
      onTap: onTap,
      allowConcurrent: allowConcurrent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
                SizedBox(width: 4.w(context)),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp(context),
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                SizedBox(width: 2.w(context)),
                Icon(
                  trailingIcon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 11.sp(context),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
