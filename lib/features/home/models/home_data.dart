import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/features/fridge/models/fridge_summary.dart';

import 'home_banner_item.dart';
import 'home_category.dart';
import 'recipe_item.dart';

class HomeData extends Equatable {
  final List<HomeBannerItem> banners;
  final List<HomeCategory> categories;
  final List<RecipeItem> recipes;
  final FridgeSummary fridgeSummary;

  HomeData({
    required List<HomeBannerItem> banners,
    required List<HomeCategory> categories,
    required List<RecipeItem> recipes,
    required this.fridgeSummary,
  }) : banners = List.unmodifiable(banners),
       categories = List.unmodifiable(categories),
       recipes = List.unmodifiable(recipes);

  const HomeData._({
    required this.banners,
    required this.categories,
    required this.recipes,
    required this.fridgeSummary,
  });

  factory HomeData.fromJson(Map<String, dynamic> json, FridgeSummary summary) {
    final reader = JsonReader(json);
    final data = HomeData(
      banners: reader.objects('banners').map(HomeBannerItem.fromJson).toList(),
      categories: reader
          .objects('categories')
          .map(HomeCategory.fromJson)
          .toList(),
      recipes: reader.objects('recipes').map(RecipeItem.fromJson).toList(),
      fridgeSummary: summary,
    );
    requireUniqueIds(data.banners.map((item) => item.id), 'banners');
    requireUniqueIds(data.categories.map((item) => item.id), 'categories');
    requireUniqueIds(data.recipes.map((item) => item.id), 'recipes');
    return data;
  }

  bool get isEmpty => banners.isEmpty && categories.isEmpty && recipes.isEmpty;

  HomeData withRecipes(List<RecipeItem> recipes) => HomeData._(
    banners: banners,
    categories: categories,
    recipes: List.unmodifiable(recipes),
    fridgeSummary: fridgeSummary,
  );

  HomeData withFridgeSummary(FridgeSummary summary) => HomeData._(
    banners: banners,
    categories: categories,
    recipes: recipes,
    fridgeSummary: summary,
  );

  @override
  List<Object> get props => [banners, categories, recipes, fridgeSummary];
}
