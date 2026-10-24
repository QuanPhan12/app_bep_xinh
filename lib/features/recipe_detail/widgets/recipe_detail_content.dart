import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';

import '../cubits/recipe_detail/recipe_detail_cubit.dart';
import 'recipe_detail_overview.dart';
import 'recipe_detail_ingredients.dart';
import 'recipe_detail_steps.dart';

class RecipeDetailContent extends StatelessWidget {
  const RecipeDetailContent({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
        buildWhen: (a, b) =>
            a.recipe != b.recipe ||
            a.tab != b.tab ||
            (a.cookingStep == null) != (b.cookingStep == null),
        builder: (context, state) {
          final recipe = state.recipe!;
          final cooking = state.cookingStep != null;
          return SingleChildScrollView(
            key: PageStorageKey('detail_${recipe.id}_$cooking'),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!cooking)
                  RecipeDetailOverview(recipe: recipe)
                else ...[
                  Text(recipe.title, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 20),
                ],
                SegmentedButton<RecipeDetailTab>(
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  segments: [
                    ButtonSegment(
                      value: RecipeDetailTab.ingredients,
                      label: Text(
                        'Nguyên liệu (${recipe.ingredients.length})',
                        style: AppTextStyles.labelMedium,
                      ),
                    ),
                    ButtonSegment(
                      value: RecipeDetailTab.steps,
                      label: Text(
                        'Cách nấu (${recipe.steps.length})',
                        style: AppTextStyles.labelMedium,
                      ),
                    ),
                  ],
                  selected: {state.tab},
                  onSelectionChanged: (values) => context
                      .read<RecipeDetailCubit>()
                      .selectTab(values.single),
                ),
                const SizedBox(height: 24),
                if (state.tab == RecipeDetailTab.ingredients)
                  const RecipeDetailIngredients()
                else
                  const RecipeDetailSteps(),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
}
