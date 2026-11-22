import 'package:app_bep_xinh/core/widgets/app_content_scroll_view.dart';
import 'package:app_bep_xinh/core/widgets/app_sliver_app_bar.dart';
import 'package:app_bep_xinh/core/widgets/app_feature_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/widgets/app_page_scaffold.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../cubits/recipe_detail/recipe_detail_cubit.dart';
import '../services/recipe_detail_service.dart';
import '../widgets/recipe_detail_content.dart';
import '../widgets/recipe_detail_actions.dart';
import '../widgets/recipe_detail_more_menu.dart';

class RecipeDetailScreen extends StatelessWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});
  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(recipeId),
    create: (context) => RecipeDetailCubit(
      recipeId: recipeId,
      service: context.read<RecipeDetailService>(),
      favorites: context.read<RecipeFavoritesService>(),
    )..load(),
    child: const AppFeatureTheme(child: _RecipeDetailPage()),
  );
}

class _RecipeDetailPage extends StatelessWidget {
  const _RecipeDetailPage();
  void _back(BuildContext context) {
    final cubit = context.read<RecipeDetailCubit>();
    if (cubit.state.cookingStep != null) {
      cubit.pauseCooking();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(PathRouter.homeScreen);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<RecipeDetailCubit, RecipeDetailState>(
    listenWhen: (a, b) => a.noticeId != b.noticeId,
    listener: (context, state) {
      if (state.message != null) {
        AppMessenger.show(
          context,
          message: state.message!,
          type: state.noticeType,
        );
      }
    },
    buildWhen: (a, b) =>
        a.status != b.status ||
        a.isFavorite != b.isFavorite ||
        a.savingFavorite != b.savingFavorite ||
        a.servings != b.servings ||
        (a.cookingStep == null) != (b.cookingStep == null),
    builder: (context, state) {
      final ready = state.status == RecipeDetailStatus.ready;
      final cubit = context.read<RecipeDetailCubit>();
      return PopScope(
        canPop: state.cookingStep == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) cubit.pauseCooking();
        },
        child: AppPageScaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppSliverAppBar(
            title: state.cookingStep == null ? 'Chi tiết món ăn' : 'Đang nấu',
            onBackPressed: () => _back(context),
            actions: ready
                ? [
                    RecipeDetailMoreMenu(
                      recipe: state.recipe!,
                      servings: state.servings,
                      isFavorite: state.isFavorite,
                      savingFavorite: state.savingFavorite,
                      onToggleFavorite: cubit.toggleFavorite,
                      isCooking: state.cookingStep != null,
                    ),
                    const SizedBox(width: 8),
                  ]
                : null,
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppLayout.pageWidth(context),
                ),
                child: ready
                    ? const RecipeDetailContent()
                    : AppLoadState(
                        isLoading:
                            state.status == RecipeDetailStatus.initial ||
                            state.status == RecipeDetailStatus.loading,
                        message: state.message,
                        onRetry: state.status == RecipeDetailStatus.notFound
                            ? null
                            : cubit.load,
                        skeleton: AppSkeleton(
                          child: AppContentScrollView(
                            padding: const EdgeInsets.all(16),
                            children: const [
                              AspectRatio(
                                aspectRatio: 1.35,
                                child: SkeletonBlock(height: 240, radius: 16),
                              ),
                              SizedBox(height: 24),
                              SkeletonLines(),
                              SizedBox(height: 24),
                              SkeletonBlock(height: 40, radius: 12),
                              SizedBox(height: 24),
                              SkeletonLines(),
                              SizedBox(height: 24),
                              SkeletonLines(),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
          bottomNavigationBar: ready ? const RecipeDetailActions() : null,
        ),
      );
    },
  );
}
