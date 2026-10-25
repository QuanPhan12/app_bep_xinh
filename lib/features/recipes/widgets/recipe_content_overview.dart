import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

import '../models/recipe_content.dart';
import '../presentation/recipe_labels.dart';
import 'recipe_image_view.dart';

import 'package:app_bep_xinh/core/widgets/app_feature_theme.dart';

class RecipeContentOverview extends StatelessWidget {
  final RecipeContent content;
  final Widget? authorInfo;
  final double? rating;
  final int? calories;
  final Widget? action;
  const RecipeContentOverview({
    super.key,
    required this.content,
    this.authorInfo,
    this.rating,
    this.calories,
    this.action,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (content.cover case final cover?)
          RecipeImageView(image: cover, aspectRatio: 1.5),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                content.title,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppFeatureTheme.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.6,
                  height: 1.25,
                ),
              ),
              if (content.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  content.description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppFeatureTheme.muted,
                    height: 1.65,
                  ),
                ),
              ],
              if (authorInfo != null) ...[
                const SizedBox(height: 10),
                authorInfo!,
              ],
              ?action,
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppFeatureTheme.herbWash,
                  borderRadius: BorderRadius.circular(AppCard.radius),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 12,
                    runSpacing: 16,
                    children: [
                      for (final item in [
                        ('Chuẩn bị', '${content.preparationMinutes} phút'),
                        ('Nấu nướng', '${content.cookingMinutes} phút'),
                        ('Khẩu phần', '${content.servings} người'),
                        ('Độ khó', content.difficulty.label),
                      ])
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.$1, style: AppTextStyles.bodySmall),
                              const SizedBox(height: 4),
                              Text(
                                item.$2,
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppFeatureTheme.herb,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (content.categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in RecipeCategory.values.where(
                      content.categories.contains,
                    ))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppFeatureTheme.peach,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category.label,
                          style: AppTextStyles.labelMedium,
                        ),
                      ),
                  ],
                ),
              ],
              if (content.meals.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  RecipeMeal.values
                      .where(content.meals.contains)
                      .map((meal) => meal.label)
                      .join(' · '),
                  style: AppTextStyles.bodySmall,
                ),
              ],
              if (rating != null || calories != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (rating != null)
                      Text(
                        'Đánh giá ${rating!.toStringAsFixed(1)} / 5',
                        style: AppTextStyles.bodySmall,
                      ),
                    if (calories != null)
                      Text(
                        '$calories kcal/phần',
                        style: AppTextStyles.bodySmall,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
