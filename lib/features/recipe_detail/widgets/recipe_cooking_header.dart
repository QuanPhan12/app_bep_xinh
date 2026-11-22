import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';

class RecipeCookingHeader extends StatelessWidget {
  final String title;
  final int active;
  final int total;
  const RecipeCookingHeader({
    super.key,
    required this.title,
    required this.active,
    required this.total,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.colors.secondaryLight,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'BƯỚC ${active + 1} / $total',
          style: AppTextStyles.labelMedium.copyWith(
            color: context.colors.secondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Đang thực hiện ${active + 1} / $total',
          style: AppTextStyles.bodySmall.copyWith(
            color: context.colors.secondary,
          ),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: (active + 1) / total,
          color: AppColors.primary,
          backgroundColor: context.colors.primary50,
          minHeight: 6,
          borderRadius: BorderRadius.circular(6),
          semanticsLabel: 'Đang ở bước ${active + 1} trên $total',
        ),
      ],
    ),
  );
}
