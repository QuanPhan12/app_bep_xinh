import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';

import 'profile_cover.dart';

import 'package:app_bep_xinh/core/widgets/app_section_header.dart';

import 'profile_photo_grid.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubits/public_profile/public_profile_cubit.dart';
import 'profile_identity_info.dart';
import '../../following/screens/following_screen.dart';

class PublicProfileContent extends StatelessWidget {
  const PublicProfileContent({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PublicProfileCubit, PublicProfileState>(
        builder: (context, state) {
          final data = state.data!;
          final user = data.user;
          final cubit = context.read<PublicProfileCubit>();
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: cubit.load,
            child: CustomScrollView(
              key: PageStorageKey('public_profile_${user.identity.id}'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  sliver: SliverToBoxAdapter(
                    child: ProfileCover(
                      child: ProfileIdentityInfo(
                        name: user.identity.name,
                        handle: user.identity.handle,
                        bio: user.bio,
                        avatarAsset: user.identity.avatarAsset,
                      ),
                    ),
                  ),
                ),
                if (user.identity.id != null)
                  SliverToBoxAdapter(
                    child: FollowAuthorControl(
                      authorId: user.identity.id!,
                      name: user.identity.name,
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: AppSectionHeader(
                      title: 'Công thức đã chia sẻ (${data.recipes.length})',
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (data.recipes.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Chưa có công thức được chia sẻ.',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ProfilePhotoGrid(
                    recipes: data.recipes,
                    onOpen: (recipe) {
                      context.push(PathRouter.recipeDetail(recipe.id));
                    },
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          );
        },
      );
}
