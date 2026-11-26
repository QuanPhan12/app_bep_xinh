import 'package:go_router/go_router.dart';

import '../../recipes/widgets/recipe_remix_attribution.dart';

import 'package:app_bep_xinh/core/widgets/app_content_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_bep_xinh/core/widgets/app_adaptive_columns.dart';
import 'package:app_bep_xinh/features/recipes/widgets/recipe_notes.dart';

import '../cubits/recipe_detail/recipe_detail_cubit.dart';
import 'recipe_detail_overview.dart';
import 'recipe_detail_ingredients.dart';
import 'recipe_detail_steps.dart';
import 'recipe_detail_tabs.dart';
import 'recipe_cooking_content.dart';

class RecipeDetailContent extends StatelessWidget {
  const RecipeDetailContent({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
    buildWhen: (a, b) =>
        a.recipe != b.recipe ||
        a.tab != b.tab ||
        (a.cookingStep == null) != (b.cookingStep == null),
    builder: (context, state) {
      if (state.cookingStep != null) return const RecipeCookingContent();
      final recipe = state.recipe!;
      return AppContentScrollView(
        key: PageStorageKey('detail_${recipe.id}_false'),
        padding: const EdgeInsets.all(16),
        children: [
          AppAdaptiveColumns(
            primary: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RecipeDetailOverview(recipe: recipe),
                if (recipe.remix != null) ...[
                  const SizedBox(height: 16),
                  RecipeRemixAttribution(
                    remix: recipe.remix!,
                    onOpen: () => context.push(
                      '/recipe/${Uri.encodeComponent(recipe.remix!.recipeId)}',
                    ),
                  ),
                ],
              ],
            ),
            secondary: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const RecipeDetailTabs(),
                const SizedBox(height: 20),
                if (state.tab == RecipeDetailTab.ingredients)
                  const RecipeDetailIngredients()
                else
                  const RecipeDetailSteps(),
                if (recipe.storageNotes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  RecipeNotes(
                    title: 'Lưu ý & bí quyết bảo quản',
                    text: recipe.storageNotes,
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}
