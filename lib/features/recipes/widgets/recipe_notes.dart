import 'package:app_bep_xinh/core/widgets/app_feature_theme.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';

class RecipeNotes extends StatelessWidget {
  final String title;
  final String text;
  const RecipeNotes({super.key, required this.title, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppFeatureTheme.herbWash,
      borderRadius: BorderRadius.circular(AppCard.radius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppFeatureTheme.herb,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(text, style: AppTextStyles.bodyMedium.copyWith(height: 1.65)),
      ],
    ),
  );
}
