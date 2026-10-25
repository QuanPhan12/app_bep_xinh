import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../utils/app_layout.dart';
import 'app_feature_theme.dart';

/// Khung thanh hành động tách từ Đăng món; nội dung nút do feature truyền vào.
class AppActionBar extends StatelessWidget {
  final Widget child;
  const AppActionBar({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border(
        top: BorderSide(
          color: AppFeatureTheme.isActive(context)
              ? AppFeatureTheme.line
              : AppColors.border,
        ),
      ),
      boxShadow: AppFeatureTheme.isActive(context)
          ? [
              BoxShadow(
                color: AppFeatureTheme.ink.withValues(alpha: .04),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ]
          : null,
    ),
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppLayout.pageWidth(context)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        ),
      ),
    ),
  );
}
