import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../dimensions/app_size.dart';
import '../text_styles/app_text_styles.dart';

/// Tiêu đề mục tách từ HomeLabelAction; feature chỉ truyền nội dung/hành động.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final EdgeInsetsGeometry padding;
  final double? maxWidth;
  final int? titleMaxLines;
  const AppSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.padding = EdgeInsets.zero,
    this.maxWidth,
    this.titleMaxLines,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: titleMaxLines,
              overflow: titleMaxLines == null ? null : TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp(context),
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
    return maxWidth == null
        ? content
        : Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth!),
              child: content,
            ),
          );
  }
}
