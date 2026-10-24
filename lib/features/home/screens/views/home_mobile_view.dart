import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../cubits/home/home.dart';
import '../../models/recipe_item.dart';
import '../../widgets/home_banner_sliver.dart';
import '../../widgets/home_categories.dart';

import 'package:app_bep_xinh/core/widgets/app_section_header.dart';
import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';

import 'package:app_bep_xinh/features/product/widgets/product_grid.dart';

import 'package:app_bep_xinh/core/widgets/app_search_bar.dart';

import 'package:app_bep_xinh/features/fridge/widgets/fridge_card.dart';

/// Giao diện Trang chủ & Khám phá dành cho thiết bị di động (Mobile View)
/// Chịu trách nhiệm hiển thị bảng tin ẩm thực, không chứa Bottom Navigation Bar
class HomeMobileView extends StatelessWidget {
  const HomeMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final (banners, categories, summary) = context.select((HomeCubit cubit) {
      final data = cubit.state.data!;
      return (data.banners, data.categories, data.fridgeSummary);
    });
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<HomeCubit>().refreshHome(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // 1. Khoảng cách đỉnh
              SliverToBoxAdapter(child: SizedBox(height: 10.h(context))),

              // 3. Thanh tìm kiếm món ăn & nguyên liệu
              SliverToBoxAdapter(
                child: AppSearchBar(
                  hintText: 'Hôm nay nấu gì?',
                  actionName: 'home_search_bar_tap',
                  padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 16.h(context))),

              // 4. Hero Banner gợi ý hôm nay (Canh sườn hầm rau củ)
              HomeBannerSliver(
                banners: banners,
                onTap: (recipeId) {
                  context.push(PathRouter.recipeDetail(recipeId));
                },
              ),

              SliverToBoxAdapter(child: SizedBox(height: 18.h(context))),

              // 5. Hàng 5 biểu tượng danh mục (Món mới, Eat Clean, Nấu nhanh, Món nước, Món chay)
              SliverToBoxAdapter(
                child: HomeCategories(
                  categories: categories,
                  onSelectCategory: (categoryId) {
                    context.read<HomeCubit>().selectCategory(categoryId);
                  },
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 18.h(context))),

              // 6. Thẻ "Tủ lạnh thông minh" (Smart Fridge Recommendation)
              SliverToBoxAdapter(
                child: FridgeCard(
                  summary: summary,
                  onExploreTap: () {
                    context.go(PathRouter.fridgeScreen);
                  },
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 20.h(context))),

              // 7. Tiêu đề mục "Món ăn thịnh hành"
              SliverToBoxAdapter(
                child: AppSectionHeader(
                  title: 'Món ăn thịnh hành',
                  titleMaxLines: 1,
                  padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
                  maxWidth: AppConstants.maxContentWidth,
                  action: const AppTextAction(
                    label: 'Xem tất cả',
                    trailingIcon: Icons.arrow_forward_ios_rounded,
                  ),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 12.h(context))),

              // 8. Lưới 2 cột hiển thị các công thức món ăn thịnh hành
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
                sliver: BlocSelector<HomeCubit, HomeState, List<RecipeItem>>(
                  selector: (state) => state.recipes,
                  builder: (context, recipes) {
                    return ProductGrid(
                      recipes: recipes,
                      columns: 2,
                      spacing: 12.w(context),
                      runSpacing: 12.h(context),
                      aspectRatio: 0.72,
                      onRecipeTap: (recipe) {
                        context.push(PathRouter.recipeDetail(recipe.id));
                      },
                      onFavoriteTap: (recipeId) =>
                          context.read<HomeCubit>().toggleFavorite(recipeId),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 16.h(context))),

              // 10. Khoảng đệm chân trang
              SliverToBoxAdapter(child: SizedBox(height: 24.h(context))),
            ],
          ),
        ),
      ),
    );
  }
}
