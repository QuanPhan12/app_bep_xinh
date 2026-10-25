import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_category.dart';

enum RecipeSearchFilter {
  all('all'),
  newest('new'),
  eatClean('eat_clean', RecipeCategory.eatClean),
  quick('quick', RecipeCategory.quick),
  soup('soup', RecipeCategory.soup),
  vegetarian('vegetarian', RecipeCategory.vegetarian);

  final String id;
  final RecipeCategory? category;
  const RecipeSearchFilter(this.id, [this.category]);

  static RecipeSearchFilter fromId(String? id) =>
      values.where((filter) => filter.id == id).firstOrNull ?? all;

  static RecipeSearchFilter fromHome(String id) => switch (id) {
    'cat_new' => newest,
    'cat_eat_clean' => eatClean,
    'cat_fast' => quick,
    'cat_soup' => soup,
    'cat_vegetarian' => vegetarian,
    _ => all,
  };
}

class RecipeSearchRequest extends Equatable {
  final String query;
  final RecipeSearchFilter filter;
  const RecipeSearchRequest({
    this.query = '',
    this.filter = RecipeSearchFilter.all,
  });
  @override
  List<Object> get props => [query, filter];
}
