import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_feature_theme.dart';
import 'package:flutter/material.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';

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
      color: AppFeatureTheme.herbWash,
      borderRadius: BorderRadius.circular(AppCard.radius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CÙNG BẠN VÀO BẾP',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppFeatureTheme.herb,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppFeatureTheme.ink,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Đang thực hiện ${active + 1} / $total',
          style: AppTextStyles.bodySmall.copyWith(color: AppFeatureTheme.herb),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: (active + 1) / total,
          color: AppColors.primary,
          backgroundColor: AppColors.primary50,
          minHeight: 6,
          borderRadius: BorderRadius.circular(6),
          semanticsLabel: 'Đang ở bước ${active + 1} trên $total',
        ),
      ],
    ),
  );
}
