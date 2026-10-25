import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';
import 'package:app_bep_xinh/features/product/widgets/product_grid.dart';

import '../cubits/profile/profile_cubit.dart';
import 'profile_identity.dart';
import 'profile_edit_sheet.dart';

import 'package:app_bep_xinh/core/widgets/app_selection_controls.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<ProfileCubit, ProfileState>(
    builder: (context, state) {
      final cubit = context.read<ProfileCubit>();
      final recipes = state.visibleRecipes;
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: cubit.load,
        child: CustomScrollView(
          key: const PageStorageKey('profile_scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              sliver: SliverToBoxAdapter(
                child: ProfileIdentity(
                  data: state.data!,
                  onEdit: () =>
                      showProfileEditSheet(context, state.data!.account),
                  onCreateRecipe: () {
                    context.push(PathRouter.recipeEditorScreen);
                  },
                  onSettings: () {
                    context.push(PathRouter.settingsScreen);
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: SegmentedButton<ProfileTab>(
                  style: AppSelectionStyles.segmented,
                  showSelectedIcon: false,
                  expandedInsets: EdgeInsets.zero,
                  segments: [
                    ButtonSegment(
                      value: ProfileTab.recipes,
                      label: Text(
                        'Công thức',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: state.tab == ProfileTab.recipes
                              ? AppColors.textWhite
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    ButtonSegment(
                      value: ProfileTab.saved,
                      label: Text(
                        'Đã lưu',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: state.tab == ProfileTab.saved
                              ? AppColors.textWhite
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  selected: {state.tab},
                  onSelectionChanged: (values) =>
                      cubit.selectTab(values.single),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            if (recipes.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: AppLoadState(
                    message: state.tab == ProfileTab.saved
                        ? 'Chưa có món đã lưu.\nLưu món bạn thích để nấu vào hôm khác.'
                        : 'Chưa có công thức.\nChia sẻ món đầu tiên từ góc bếp của bạn.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: ProductGrid(
                  recipes: recipes,
                  spacing: 12,
                  runSpacing: 12,
                  aspectRatio: 1,
                  onRecipeTap: (recipe) {
                    context.push(PathRouter.recipeDetail(recipe.id));
                  },
                  onFavoriteTap: cubit.toggleFavorite,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      );
    },
  );
}
