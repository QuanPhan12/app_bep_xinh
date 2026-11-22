import 'package:app_bep_xinh/core/widgets/app_selection_controls.dart';
import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/tap/tap_extension.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:app_bep_xinh/features/product/widgets/product_grid.dart';

import '../../../core/utils/app_layout.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/fridge/fridge_cubit.dart';
import '../models/fridge_recipe.dart';

class FridgeRecipeSuggestions extends StatelessWidget {
  const FridgeRecipeSuggestions({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<FridgeCubit, FridgeState>(
    buildWhen: (a, b) =>
        a.selectedIds != b.selectedIds ||
        a.data != b.data ||
        a.filter != b.filter,
    builder: (context, state) {
      final ready = state.readyRecipes;
      final almostReady = state.almostReadyRecipes;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final filter in FridgeRecipeFilter.values)
                AppChoiceChip(
                  label: switch (filter) {
                    FridgeRecipeFilter.all => 'Tất cả',
                    FridgeRecipeFilter.quick => '≤ 15 phút',
                    FridgeRecipeFilter.vegetarian => 'Món chay',
                  },
                  selected: state.filter == filter,
                  onSelected: (_) => context
                      .onAppTap(
                        () => context.read<FridgeCubit>().selectFilter(filter),
                        actionName: 'fridge_filter_${filter.name}',
                      )
                      ?.call(),
                ),
            ],
          ),
          SizedBox(height: 16.h(context)),
          if (ready.isEmpty && almostReady.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w(context)),
              decoration: BoxDecoration(
                color: context.colors.primary50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                state.selectedIds.isEmpty
                    ? 'Thêm nguyên liệu để xem món có thể nấu nhé.'
                    : 'Chưa có món phù hợp. Thử thêm nguyên liệu hoặc đổi bộ lọc nhé.',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          if (ready.isNotEmpty) ...[
            Text(
              'Nấu được ngay · ${ready.length} món',
              style: AppTextStyles.titleSmall,
            ),
            SizedBox(height: 10.h(context)),
            _recipes(context, ready, state),
          ],
          if (almostReady.isNotEmpty) ...[
            SizedBox(height: 20.h(context)),
            Text(
              'Thiếu 1 nguyên liệu · ${almostReady.length} món',
              style: AppTextStyles.titleSmall,
            ),
            SizedBox(height: 10.h(context)),
            _recipes(context, almostReady, state, missing: true),
          ],
        ],
      );
    },
  );

  Widget _recipes(
    BuildContext context,
    List<FridgeRecipe> recipes,
    FridgeState state, {
    bool missing = false,
  }) {
    final byId = {for (final recipe in recipes) recipe.id: recipe};
    return LayoutBuilder(
      builder: (context, constraints) => ProductGrid(
        sliver: false,
        columns: AppLayout.gridColumns(constraints.maxWidth).clamp(2, 3),
        recipes: [
          for (final recipe in recipes)
            RecipeItem(
              id: recipe.id,
              title: recipe.title,
              image: recipe.image ?? '',
              // Nguồn tủ lạnh chưa có đánh giá; số 0 khiến card chung bỏ dòng sao.
              rating: 0,
              cookTimeMinutes: recipe.minutes,
              tag: '',
            ),
        ],
        spacing: 12.w(context),
        runSpacing: 12.h(context),

        supportingTextBuilder: missing
            ? (recipe) =>
                  'Cần thêm: ${byId[recipe.id]!.missingIngredients(state.selectedIds).map(state.ingredientName).join(', ')}'
            : null,
        onRecipeTap: (recipe) {
          context.push(PathRouter.recipeDetail(recipe.id));
        },
      ),
    );
  }
}
