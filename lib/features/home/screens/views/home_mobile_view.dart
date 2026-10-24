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
import '../../widgets/home_label_action.dart';
import 'package:app_bep_xinh/features/product/widgets/product_card.dart';
import '../../widgets/home_search_bar.dart';
import '../../widgets/home_smart_fridge_card.dart';

/// Giao diện Trang chủ & Khám phá dành cho thiết bị di động (Mobile View)
/// Chịu trách nhiệm hiển thị bảng tin ẩm thực, không chứa Bottom Navigation Bar
class HomeMobileView extends StatelessWidget {
  const HomeMobileView({super.key});

  @override
  Widget build(BuildContext context) {
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
              const SliverToBoxAdapter(child: HomeSearchBar()),

              SliverToBoxAdapter(child: SizedBox(height: 16.h(context))),

              // 4. Hero Banner gợi ý hôm nay (Canh sườn hầm rau củ)
              SliverToBoxAdapter(
                child: HomeBanner(
                  onTap: (recipeId) {
                    context.push(
                      PathRouter.recipeDetail(recipeId),
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 18.h(context))),

              // 5. Hàng 5 biểu tượng danh mục (Món mới, Eat Clean, Nấu nhanh, Món nước, Món chay)
              SliverToBoxAdapter(
                child: HomeCategories(
                  onSelectCategory: (categoryId) {
                    context.read<HomeCubit>().selectCategory(categoryId);
                  },
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 18.h(context))),

              // 6. Thẻ "Tủ lạnh thông minh" (Smart Fridge Recommendation)
              SliverToBoxAdapter(
                child: HomeSmartFridgeCard(
                  onExploreTap: () {
                    context.go(PathRouter.fridgeScreen);
                  },
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 20.h(context))),

              // 7. Tiêu đề mục "Món ăn thịnh hành"
              const SliverToBoxAdapter(
                child: HomeLabelAction(label: 'Món ăn thịnh hành'),
              ),

              SliverToBoxAdapter(child: SizedBox(height: 12.h(context))),

              // 8. Lưới 2 cột hiển thị các công thức món ăn thịnh hành
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
                sliver: BlocSelector<HomeCubit, HomeState, List<RecipeItem>>(
                  selector: (state) => state.recipes,
                  builder: (context, recipes) {
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w(context),
                        mainAxisSpacing: 12.h(context),
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final recipe = recipes[index];
                        return ProductCard(
                          recipe: recipe,
                          onTap: () {
                            context.push(PathRouter.recipeDetail(recipe.id));
                          },
                          onFavoriteTap: () {
                            context.read<HomeCubit>().toggleFavorite(recipe.id);
                          },
                        );
                      }, childCount: recipes.length),
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
