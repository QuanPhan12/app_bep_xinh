import 'profile_recipe_empty_state.dart';

import 'package:app_bep_xinh/core/widgets/app_sliver_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/utils/app_layout.dart';

import 'profile_photo_grid.dart';

import '../cubits/profile/profile_cubit.dart';
import 'profile_identity.dart';
import 'profile_app_bar.dart';
import 'profile_recipe_tabs.dart';
import 'profile_recipe_filters.dart';
import '../../kitchen/services/kitchen_services.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key});
  Future<void> _createRecipe(BuildContext context) async {
    final cubit = context.read<ProfileCubit>();
    await context.push(PathRouter.recipeEditorScreen);
    if (context.mounted && !cubit.isClosed) await cubit.load();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ProfileCubit, ProfileState>(
    builder: (context, state) {
      final cubit = context.read<ProfileCubit>();
      final recipes = state.visibleRecipes;
      final collection = state.tab == ProfileTab.saved
          ? state.data!.savedRecipes
          : state.data!.ownRecipes;
      void selectCollection(ProfileTab tab) {
        cubit.selectFilter(ProfileRecipeFilter.all);
        cubit.selectTab(tab);
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: cubit.load,
        child: CustomScrollView(
          key: const PageStorageKey('profile_scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            ProfileAppBar(
              onSettings: () => context.push(PathRouter.settingsScreen),
            ),
            AppSliverContent(
              maxWidth: AppLayout.pageWidth(context),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 20),
                  sliver: SliverToBoxAdapter(
                    child: ProfileIdentity(
                      data: state.data!,
                      useJournalCount: KitchenScope.maybeOf(context) != null,
                      journalCount: state.cookingLogCount,
                      onEdit: () => context.push(PathRouter.profileEditScreen),
                      onCreate:
                          state.data!.ownRecipes.isNotEmpty ||
                              state.tab == ProfileTab.saved
                          ? () => _createRecipe(context)
                          : null,
                      onSelectRecipes: () =>
                          selectCollection(ProfileTab.recipes),
                      onSelectSaved: () => selectCollection(ProfileTab.saved),
                      onOpenJournal: KitchenScope.maybeOf(context) == null
                          ? null
                          : () => context.push('/kitchen/journal'),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.zero,
                  sliver: SliverToBoxAdapter(
                    child: ProfileRecipeTabs(
                      selected: state.tab,
                      onSelected: cubit.selectTab,
                    ),
                  ),
                ),
                if (collection.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16.w(context),
                      10,
                      16.w(context),
                      10,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: ProfileRecipeFilters(
                        selected: state.filter,
                        onSelected: cubit.selectFilter,
                      ),
                    ),
                  ),
                if (recipes.isEmpty)
                  SliverToBoxAdapter(
                    child: ProfileRecipeEmptyState(
                      saved: state.tab == ProfileTab.saved,
                      filtered:
                          collection.isNotEmpty &&
                          state.filter != ProfileRecipeFilter.all,
                      onCreate: () => _createRecipe(context),
                      onExplore: () => context.go('/home'),
                      onClearFilter: () =>
                          cubit.selectFilter(ProfileRecipeFilter.all),
                    ),
                  )
                else
                  ProfilePhotoGrid(
                    recipes: recipes,
                    onOpen: (recipe) {
                      context.push(PathRouter.recipeDetail(recipe.id));
                    },
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          ],
        ),
      );
    },
  );
}
