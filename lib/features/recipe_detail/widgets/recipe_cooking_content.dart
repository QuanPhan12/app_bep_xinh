import 'recipe_cooking_header.dart';

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/tap/tap_extension.dart';
import 'package:app_bep_xinh/core/widgets/app_adaptive_columns.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';
import 'package:app_bep_xinh/core/widgets/app_section_header.dart';
import 'package:app_bep_xinh/features/recipes/widgets/recipe_notes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_detail/recipe_detail_cubit.dart';
import 'recipe_detail_ingredients.dart';
import 'recipe_detail_steps.dart';
import 'recipe_detail_tabs.dart';

class RecipeCookingContent extends StatelessWidget {
  const RecipeCookingContent({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
        buildWhen: (a, b) =>
            a.recipe != b.recipe ||
            a.cookingStep != b.cookingStep ||
            a.tab != b.tab,
        builder: (context, state) {
          final recipe = state.recipe!;
          final active = state.cookingStep;
          if (active == null) return const SizedBox.shrink();
          final cubit = context.read<RecipeDetailCubit>();
          return SingleChildScrollView(
            key: ValueKey('cooking_${recipe.id}_${state.tab.name}_$active'),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RecipeCookingHeader(
                  title: recipe.title,
                  active: active,
                  total: recipe.steps.length,
                ),
                const SizedBox(height: 20),
                AppAdaptiveColumns(
                  primaryFlex: 3,
                  secondaryFlex: 2,
                  primary: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const RecipeDetailTabs(),
                      const SizedBox(height: 20),
                      if (state.tab == RecipeDetailTab.ingredients)
                        const RecipeDetailIngredients()
                      else
                        const RecipeDetailSteps(),
                    ],
                  ),
                  secondary: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Material(
                          type: MaterialType.transparency,
                          child: Column(
                            children: [
                              const AppSectionHeader(title: 'Các bước nấu'),
                              const SizedBox(height: 12),
                              for (
                                var index = 0;
                                index < recipe.steps.length;
                                index++
                              )
                                ListTile(
                                  key: ValueKey(
                                    'cooking_jump_${recipe.steps[index].id}',
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  selected: active == index,
                                  selectedTileColor: AppColors.primary50,
                                  leading: Text(
                                    '${index + 1}',
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  title: Text(
                                    recipe.steps[index].title.isEmpty
                                        ? 'Bước ${index + 1}'
                                        : recipe.steps[index].title,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  subtitle: recipe.steps[index].minutes == null
                                      ? null
                                      : Text(
                                          '${recipe.steps[index].minutes} phút',
                                          style: AppTextStyles.bodySmall,
                                        ),
                                  onTap: context.onAppTap(
                                    () => cubit.goToCookingStep(index),
                                    actionName: 'recipe_cooking_jump',
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
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
            ),
          );
        },
      );
}
