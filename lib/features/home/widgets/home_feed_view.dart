import '../../../core/widgets/app_search_bar.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/tap/tap_extension.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_messenger.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/cubits/recipe_tools_cubit.dart';
import '../../recipe_search/models/recipe_search_request.dart';
import '../cubits/home/home.dart';
import '../models/recipe_item.dart';
import '../../recipes/widgets/recipe_image_gallery.dart';
import 'home_app_bar.dart';
import 'home_categories.dart';
import '../models/home_banner_item.dart';

class HomeFeedView extends StatelessWidget {
  const HomeFeedView({super.key});
  @override
  Widget build(BuildContext context) {
    final services = KitchenScope.maybeOf(context);
    if (services == null) return const _FeedBody();
    return BlocProvider(
      create: (_) => RecipeToolsCubit(services),
      child: BlocListener<RecipeToolsCubit, RecipeToolsState>(
        listenWhen: (a, b) => b.message != null && a.message != b.message,
        listener: (context, state) =>
            AppMessenger.show(context, message: state.message!),
        child: const _FeedBody(),
      ),
    );
  }
}

class _FeedBody extends StatelessWidget {
  const _FeedBody();
  @override
  Widget build(BuildContext context) {
    final data = context.select((HomeCubit cubit) => cubit.state.data!);
    final services = KitchenScope.maybeOf(context);
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final feed = RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().refreshHome(),
              child: CustomScrollView(
                key: const PageStorageKey('home_content'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const HomeAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: AppSearchBar(
                        key: const ValueKey('home_search'),
                        hintText: 'Tìm món ăn, nguyên liệu…',
                        onTap: () => context.push(PathRouter.recipeSearch()),
                      ),
                    ),
                  ),
                  if (data.banners.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _FeaturedRecipes(banners: data.banners),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: HomeCategories(
                        categories: data.categories,
                        onSelectCategory: (id) => context.push(
                          PathRouter.recipeSearch(
                            filter: RecipeSearchFilter.fromHome(id),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: data.recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = data.recipes[index];
                      return HomeRecipePost(
                        key: ValueKey('feed_${recipe.id}'),
                        recipe: recipe,
                        onOpen: () =>
                            context.push(PathRouter.recipeDetail(recipe.id)),
                        onSource: recipe.remix == null
                            ? null
                            : () => context.push(
                                PathRouter.recipeDetail(recipe.remix!.recipeId),
                              ),
                        onFavorite: () =>
                            context.read<HomeCubit>().toggleFavorite(recipe.id),
                        onAuthor: recipe.authorId == null
                            ? null
                            : () => context.push(
                                '/users/${Uri.encodeComponent(recipe.authorId!)}',
                              ),
                        onReview: recipe.id.startsWith('r_')
                            ? () => context.push(
                                '/recipe/${Uri.encodeComponent(recipe.id)}/reviews',
                              )
                            : null,
                        onShare: services == null
                            ? null
                            : () {
                                final box =
                                    context.findRenderObject() as RenderBox?;
                                context.read<RecipeToolsCubit>().share(
                                  recipe.id,
                                  box == null
                                      ? const Rect.fromLTWH(0, 0, 1, 1)
                                      : box.localToGlobal(Offset.zero) &
                                            box.size,
                                );
                              },
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            );
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 1060 : 630),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: feed),
                    if (wide) ...[
                      const SizedBox(width: 48),
                      SizedBox(
                        width: 280,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(
                            top: 48,
                            right: 16,
                            bottom: 32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Góc bếp của bạn',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Chuẩn bị hôm nay, nấu ngon mỗi ngày.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: context.colors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              for (final entry in [
                                (
                                  'Tủ lạnh',
                                  PhosphorIconsRegular.snowflake,
                                  '/fridge',
                                ),
                                (
                                  'Thực đơn tuần',
                                  PhosphorIconsRegular.calendarBlank,
                                  '/kitchen/meal-plan',
                                ),
                                (
                                  'Công thức đã tải',
                                  PhosphorIconsRegular.downloadSimple,
                                  '/kitchen/offline',
                                ),
                                (
                                  'Nhật ký nấu ăn',
                                  PhosphorIconsRegular.notebook,
                                  '/kitchen/journal',
                                ),
                              ])
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(entry.$2),
                                  title: Text(entry.$1),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                    size: 18,
                                  ),
                                  onTap: () => context.push(entry.$3),
                                ),
                              const SizedBox(height: 24),
                              Text(
                                'BẾP XINH',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: context.colors.textSecondary,
                                      letterSpacing: 2,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Chỉ hiển thị tác giả và trạng thái lưu có dữ liệu thật; không tạo số like hay thời gian đăng giả.
class HomeRecipePost extends StatelessWidget {
  final RecipeItem recipe;
  final VoidCallback onOpen;
  final FutureOr<void> Function()? onFavorite;
  final VoidCallback? onAuthor, onReview, onShare, onSource;
  const HomeRecipePost({
    super.key,
    required this.recipe,
    required this.onOpen,
    required this.onFavorite,
    this.onAuthor,
    this.onReview,
    this.onShare,
    this.onSource,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
              child: Row(
                children: [
                  AppAvatar(name: recipe.authorName ?? 'Bếp Xinh', size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: onAuthor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.authorName ?? 'Bếp Xinh',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${recipe.cookTimeMinutes} phút · ${recipe.difficulty}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: context.colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (recipe.remix != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Tooltip(
                  message: 'Xem công thức gốc: ${recipe.remix!.title}',
                  child: InkWell(
                    key: ValueKey('post_remix_source_${recipe.id}'),
                    onTap: onSource,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIconsRegular.linkSimple,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(text: 'Biến tấu từ '),
                                  TextSpan(
                                    text: recipe.remix!.authorName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                recipe.title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600, height: 1.35),
              ),
            ),
            RecipeImageGallery(
              key: ValueKey('post_gallery_${recipe.id}'),
              useDots: true,
              itemCount: recipe.imageSources.length,
              itemBuilder: (context, index) => FeedRecipeImage(
                source: recipe.imageSources[index],
                label: recipe.title,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 14, 8),
              child: Row(
                children: [
                  if (onFavorite != null)
                    IconButton(
                      // tooltip: recipe.isFavorite
                      //     ? 'Bỏ lưu công thức'
                      //     : 'Lưu công thức',
                      onPressed: context.onAppTap(
                        onFavorite,
                        actionName: 'feed_favorite',
                        requiresAuth: true,
                      ),
                      icon: Icon(
                        recipe.isFavorite
                            ? PhosphorIconsFill.heart
                            : PhosphorIconsRegular.heart,
                        color: recipe.isFavorite
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        size: 20,
                      ),
                    ),
                  if (onReview != null)
                    IconButton(
                      // tooltip: 'Đánh giá cộng đồng',
                      onPressed: onReview,
                      icon: const Icon(PhosphorIconsRegular.star, size: 20),
                    ),
                  if (onShare != null)
                    IconButton(
                      // tooltip: 'Chia sẻ công thức',
                      onPressed: onShare,
                      icon: const Icon(
                        PhosphorIconsRegular.paperPlaneTilt,
                        size: 20,
                      ),
                    ),
                  const Spacer(),
                  if (recipe.rating > 0) ...[
                    Icon(
                      PhosphorIconsFill.star,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      recipe.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class FeedRecipeImage extends StatelessWidget {
  final String source, label;
  const FeedRecipeImage({super.key, required this.source, required this.label});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width =
          (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
              .round()
              .clamp(1, 1400);
      Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
          ColoredBox(
            color: context.colors.surfaceVariant,
            child: const Center(
              child: Icon(PhosphorIconsRegular.forkKnife, size: 32),
            ),
          );
      return source.startsWith('https://')
          ? Image.network(
              source,
              fit: BoxFit.cover,
              cacheWidth: width,
              semanticLabel: label,
              errorBuilder: fallback,
            )
          : Image.asset(
              source,
              fit: BoxFit.cover,
              cacheWidth: width,
              semanticLabel: label,
              errorBuilder: fallback,
            );
    },
  );
}

class _FeaturedRecipes extends StatelessWidget {
  final List<HomeBannerItem> banners;
  const _FeaturedRecipes({required this.banners});
  @override
  Widget build(BuildContext context) {
    final text = MediaQuery.textScalerOf(context);
    // Thẻ ngang dành chỗ cho tên hai dòng và thời gian nấu kể cả khi tăng cỡ chữ.
    // Dự phòng làm tròn font metrics ở cỡ chữ lớn để không tràn dưới một pixel.
    final height = (text.scale(14) * 1.35 * 2 + text.scale(12) * 1.4 + 24)
        .ceilToDouble()
        .clamp(96.0, double.infinity)
        .toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const AppSectionHeader(title: 'Món nổi bật'),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: banners.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final banner = banners[i];
                return SizedBox(
                  width: 264,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('story_${banner.id}'),
                      onTap: () =>
                          context.push(PathRouter.recipeDetail(banner.id)),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox.square(
                                dimension: 80,
                                child: FeedRecipeImage(
                                  source: banner.image,
                                  label: banner.title,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    banner.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: 14,
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    banner.cookTime,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: context.colors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
