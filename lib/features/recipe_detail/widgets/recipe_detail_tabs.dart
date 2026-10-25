import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/widgets/app_selection_controls.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';

import '../cubits/recipe_detail/recipe_detail_cubit.dart';

class RecipeDetailTabs extends StatelessWidget {
  const RecipeDetailTabs({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
        buildWhen: (a, b) => a.recipe != b.recipe || a.tab != b.tab,
        builder: (context, state) {
          final recipe = state.recipe!;
          return SegmentedButton<RecipeDetailTab>(
            style: AppSelectionStyles.segmented,
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            segments: [
              ButtonSegment(
                value: RecipeDetailTab.ingredients,
                label: Text(
                  'Nguyên liệu (${recipe.ingredients.length})',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: state.tab == RecipeDetailTab.ingredients
                        ? AppColors.textWhite
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              ButtonSegment(
                value: RecipeDetailTab.steps,
                label: Text(
                  'Cách nấu (${recipe.steps.length})',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: state.tab == RecipeDetailTab.steps
                        ? AppColors.textWhite
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            selected: {state.tab},
            onSelectionChanged: (values) =>
                context.read<RecipeDetailCubit>().selectTab(values.single),
          );
        },
      );
}
