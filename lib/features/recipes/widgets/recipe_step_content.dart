import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

import '../models/recipe_content.dart';
import 'recipe_image_view.dart';
import 'recipe_notes.dart';

import 'package:app_bep_xinh/core/widgets/app_feature_theme.dart';

class RecipeStepContent extends StatelessWidget {
  final RecipeStep step;
  final int number;
  final int? total;
  const RecipeStepContent({
    super.key,
    required this.step,
    required this.number,
    this.total,
  });
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppFeatureTheme.herbWash,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                total == null ? 'Bước $number' : 'Bước $number / $total',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppFeatureTheme.herb,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (step.minutes != null)
              Text('${step.minutes} phút', style: AppTextStyles.bodySmall),
          ],
        ),
        if (step.title.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            step.title,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          step.instruction,
          style: AppTextStyles.bodyMedium.copyWith(height: 1.75),
        ),
        if (step.photo case final photo?) ...[
          const SizedBox(height: 16),
          RecipeImageView(image: photo),
        ],
        if (step.tip.isNotEmpty) ...[
          const SizedBox(height: 16),
          RecipeNotes(title: 'Mẹo nhỏ', text: step.tip),
        ],
      ],
    ),
  );
}
