import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';

import 'recipe_section.dart';

import 'package:flutter/material.dart';

import '../models/recipe_content.dart';
import 'recipe_image_view.dart';
import 'recipe_notes.dart';

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
  Widget build(BuildContext context) => RecipeSection(
    title: total == null ? 'Bước $number' : 'Bước $number / $total',
    action: step.minutes == null
        ? null
        : Text('${step.minutes} phút', style: AppTextStyles.bodySmall),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (step.title.isNotEmpty) ...[
          Text(
            step.title,
            style: AppTextStyles.titleSmall.copyWith(
              color: context.colors.textPrimary,
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
