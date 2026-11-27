import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';
import 'package:app_bep_xinh/features/product/widgets/product_grid.dart';

import '../cubits/recipe_search_cubit.dart';

class RecipeSearchResults extends StatelessWidget {
  final List<Widget> headerSlivers;
  const RecipeSearchResults({super.key, this.headerSlivers = const []});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<RecipeSearchCubit, RecipeSearchState>(
    builder: (context, state) {
      final loading =
          state.status == RecipeSearchStatus.initial ||
          state.status == RecipeSearchStatus.loading;
      final failed = state.status == RecipeSearchStatus.failure;
      return CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          ...headerSlivers,
          if (loading || failed || state.recipes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppLoadState(
                isLoading: loading,
                message: loading
                    ? null
                    : failed
                    ? state.message
                    : 'Chưa có món phù hợp. Thử tên món, nguyên liệu khác hoặc đổi danh mục nhé.',
                onRetry: failed ? context.read<RecipeSearchCubit>().load : null,
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${state.recipes.length} món ăn',
                  style: AppTextStyles.titleSmall,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: ProductGrid(
                recipes: state.recipes,
                spacing: 16,
                runSpacing: 16,

                onRecipeTap: (recipe) {
                  context.read<RecipeSearchCubit>().rememberCurrentQuery();
                  context.push(PathRouter.recipeDetail(recipe.id));
                },
                onFavoriteTap: context.read<RecipeSearchCubit>().toggleFavorite,
              ),
            ),
          ],
        ],
      );
    },
  );
}
