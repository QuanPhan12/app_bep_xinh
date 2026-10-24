import 'package:flutter/material.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';

import '../models/recipe_detail.dart';

class RecipeDetailOverview extends StatelessWidget {
  final RecipeDetail recipe;
  const RecipeDetailOverview({super.key, required this.recipe});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (recipe.image case final image?) ...[
        AppCard(
          child: AspectRatio(
            aspectRatio: 1.35,
            child: LayoutBuilder(
              builder: (context, constraints) => Image.asset(
                image,
                fit: BoxFit.cover,
                cacheWidth:
                    (constraints.maxWidth *
                            MediaQuery.devicePixelRatioOf(context))
                        .round()
                        .clamp(1, 2048),
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.surfaceVariant,
                  child: Center(
                    child: Icon(
                      Icons.restaurant_outlined,
                      color: AppColors.textTertiary,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
      Text(
        recipe.title,
        style: AppTextStyles.headlineSmall.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 14,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (recipe.rating != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.accent,
                  size: 17,
                ),
                const SizedBox(width: 4),
                Text(
                  recipe.rating!.toStringAsFixed(1),
                  style: AppTextStyles.labelMedium,
                ),
              ],
            ),
          Text(
            '${recipe.preparationMinutes + recipe.cookingMinutes} phút',
            style: AppTextStyles.bodySmall,
          ),
          Text(recipe.difficulty, style: AppTextStyles.bodySmall),
          if (recipe.calories != null)
            Text(
              '${recipe.calories} kcal/phần',
              style: AppTextStyles.bodySmall,
            ),
        ],
      ),
      const SizedBox(height: 16),
      Text(recipe.description, style: AppTextStyles.bodyMedium),
      const SizedBox(height: 10),
      Text('Công thức của ${recipe.author}', style: AppTextStyles.bodySmall),
      const SizedBox(height: 20),
      const Divider(height: 1),
      const SizedBox(height: 20),
    ],
  );
}
