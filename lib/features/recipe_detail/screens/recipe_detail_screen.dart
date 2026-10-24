import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/tap/tap_extension.dart';
import 'package:app_bep_xinh/core/widgets/app_app_bar.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../cubits/recipe_detail/recipe_detail_cubit.dart';
import '../services/recipe_detail_service.dart';
import '../widgets/recipe_detail_content.dart';
import '../widgets/recipe_detail_actions.dart';

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
    child: const _RecipeDetailPage(),
  );
}

class _RecipeDetailPage extends StatelessWidget {
  const _RecipeDetailPage();
  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(PathRouter.homeScreen);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<RecipeDetailCubit, RecipeDetailState>(
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
            (a.cookingStep == null) != (b.cookingStep == null),
        builder: (context, state) {
          final ready = state.status == RecipeDetailStatus.ready;
          final cubit = context.read<RecipeDetailCubit>();
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppAppBar(
              title: state.cookingStep == null ? 'Chi tiết món ăn' : 'Đang nấu',
              onBack: () => _back(context),
              actions: ready
                  ? [
                      IconButton(
                        tooltip: state.isFavorite ? 'Bỏ lưu món' : 'Lưu món',
                        icon: Icon(
                          state.isFavorite
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: state.isFavorite
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        onPressed: state.savingFavorite
                            ? null
                            : context.onAppTap(
                                cubit.toggleFavorite,
                                actionName: 'recipe_detail_favorite',
                              ),
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
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.maxContentWidth,
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
                            child: ListView(
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
          );
        },
      );
}
