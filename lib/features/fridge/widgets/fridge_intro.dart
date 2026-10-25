import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_feature_theme.dart';
import 'package:flutter/material.dart';

class FridgeIntro extends StatelessWidget {
  const FridgeIntro({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Tủ lạnh thông minh',
        style: AppTextStyles.headlineSmall.copyWith(
          color: AppFeatureTheme.ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -.5,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Tận dụng nguyên liệu, thêm ngon mỗi bữa.',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppFeatureTheme.muted,
          fontSize: 13,
        ),
      ),
    ],
  );
}
