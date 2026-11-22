import 'home_banner_item.dart';
import 'home_data.dart';
import 'recipe_item.dart';

class HomeFeed {
  final List<RecipeItem> recipes;
  final List<HomeBannerItem> banners;
  HomeFeed({
    required List<RecipeItem> recipes,
    required List<HomeBannerItem> banners,
  }) : recipes = List.unmodifiable(recipes),
       banners = List.unmodifiable(banners);

  HomeData applyTo(HomeData data) =>
      data.withRecipes(recipes).withBanners(banners);
}
