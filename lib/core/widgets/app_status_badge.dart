import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../text_styles/app_text_styles.dart';

enum AppStatusTone { pending, success, attention }

/// Trạng thái có cả chữ và icon để không phụ thuộc riêng màu sắc.
class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusTone tone;
  const AppStatusBadge({super.key, required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (tone) {
      AppStatusTone.pending => (
        context.colors.primary50,
        AppColors.primary900,
        Icons.schedule,
      ),
      AppStatusTone.success => (
        context.colors.secondaryLight,
        context.colors.secondary,
        Icons.check_circle_outline,
      ),
      AppStatusTone.attention => (
        context.colors.errorBg,
        context.colors.error,
        Icons.info_outline,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
