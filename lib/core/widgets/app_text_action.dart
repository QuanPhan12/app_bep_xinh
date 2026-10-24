import 'dart:async';

import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
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
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: AppColors.primary, size: 13.sp(context)),
              SizedBox(width: 4.w(context)),
            ],
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp(context),
              ),
            ),
            if (trailingIcon != null) ...[
              SizedBox(width: 2.w(context)),
              Icon(
                trailingIcon,
                color: AppColors.primary,
                size: 11.sp(context),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
