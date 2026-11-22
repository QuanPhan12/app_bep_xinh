import 'package:flutter/material.dart';

import '../colors/app_colors.dart';

/// Tiêu đề mục tách từ HomeLabelAction; feature chỉ truyền nội dung/hành động.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final String? subtitle;
  final EdgeInsetsGeometry padding;
  final double? maxWidth;
  final int? titleMaxLines;
  const AppSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.subtitle,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: titleMaxLines == null
                        ? null
                        : TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                      letterSpacing: -.3,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
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
