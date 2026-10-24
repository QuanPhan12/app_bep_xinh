import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../cubits/home/home.dart';
import '../../models/recipe_item.dart';
import '../../widgets/home_banner.dart';
import '../../widgets/home_categories.dart';
import '../../widgets/home_header.dart';
import '../../widgets/home_label_action.dart';
import 'package:app_bep_xinh/features/product/widgets/product_card.dart';
import 'package:app_bep_xinh/features/product/widgets/product_slider.dart';
import '../../widgets/home_search_bar.dart';
import '../../widgets/home_smart_fridge_card.dart';

/// Giao diện Trang chủ Bếp Xinh tối ưu hóa cho Máy tính bảng (Tablet View)
/// Bố cục rộng rãi, co giãn thông minh, lưới 3 cột hiện đại
class HomeTabletView extends StatelessWidget {
  const HomeTabletView({super.key});

  static const double _maxTabletContentWidth = 680.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxTabletContentWidth),
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<HomeCubit>().refreshHome(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: 16.h(context))),

                  // Header
                  const SliverToBoxAdapter(child: HomeHeader()),

                  SliverToBoxAdapter(child: SizedBox(height: 16.h(context))),

                  // Thanh tìm kiếm
                  const SliverToBoxAdapter(child: HomeSearchBar()),

                  SliverToBoxAdapter(child: SizedBox(height: 20.h(context))),

                  // Hero Banner Carousel
                  SliverToBoxAdapter(
                    child: HomeBanner(
                      onTap: (recipeId) {
                        context.push(
                          PathRouter.recipeDetail(recipeId),
                        );
                      },
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 24.h(context))),

                  // 5 danh mục
                  SliverToBoxAdapter(
                    child: HomeCategories(
                      onSelectCategory: (categoryId) {
                        context.read<HomeCubit>().selectCategory(categoryId);
                      },
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 24.h(context))),

                  // Tủ lạnh thông minh
                  SliverToBoxAdapter(
                    child: HomeSmartFridgeCard(
                      onExploreTap: () {
                        context.go(PathRouter.fridgeScreen);
                      },
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 28.h(context))),

                  // Widget Slider Món ăn thịnh hành chuyên dụng trên Tablet
                  SliverToBoxAdapter(
                    child: BlocSelector<HomeCubit, HomeState, List<RecipeItem>>(
                      selector: (state) => state.recipes,
                      builder: (context, recipes) {
                        return ProductSlider(
                          title: 'Món ăn thịnh hành',
                          recipes: recipes,
                          onRecipeTap: (recipe) {
                            context.push(
                              PathRouter.recipeDetail(recipe.id),
                            );
                          },
                          onFavoriteTap: (recipeId) {
                            context.read<HomeCubit>().toggleFavorite(recipeId);
                          },
                        );
                      },
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 28.h(context))),

                  // Tiêu đề Khám phá tất cả món ngon
                  const SliverToBoxAdapter(
                    child: HomeLabelAction(label: 'Khám phá tất cả món ngon'),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 16.h(context))),

                  // Lưới 3 cột trên Tablet
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
                    sliver:
                        BlocSelector<HomeCubit, HomeState, List<RecipeItem>>(
                          selector: (state) => state.recipes,
                          builder: (context, recipes) {
                            return SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 16.w(context),
                                    mainAxisSpacing: 16.h(context),
                                    childAspectRatio: 0.75,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final recipe = recipes[index];
                                return ProductCard(
                                  recipe: recipe,
                                  onTap: () {
                                    context.push(
                                      PathRouter.recipeDetail(recipe.id),
                                    );
                                  },
                                  onFavoriteTap: () {
                                    context.read<HomeCubit>().toggleFavorite(
                                      recipe.id,
                                    );
                                  },
                                );
                              }, childCount: recipes.length),
                            );
                          },
                        ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: 24.h(context))),

                  SliverToBoxAdapter(child: SizedBox(height: 32.h(context))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
