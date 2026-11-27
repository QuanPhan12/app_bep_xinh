import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_category.dart';

import '../../recipes/models/recipe_content.dart' show RecipeDifficulty;
export '../../recipes/models/recipe_content.dart' show RecipeDifficulty;

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
  final int? maxMinutes;
  final RecipeDifficulty? difficulty;
  final String excludedIngredients;
  const RecipeSearchRequest({
    this.query = '',
    this.filter = RecipeSearchFilter.all,
    this.maxMinutes,
    this.difficulty,
    this.excludedIngredients = '',
  });
  int get advancedCount =>
      (maxMinutes == null ? 0 : 1) +
      (difficulty == null ? 0 : 1) +
      (excludedIngredients.trim().isEmpty ? 0 : 1);

  RecipeSearchRequest copyWith({
    String? query,
    RecipeSearchFilter? filter,
    int? maxMinutes,
    RecipeDifficulty? difficulty,
    String? excludedIngredients,
    bool clearMinutes = false,
    bool clearDifficulty = false,
  }) => RecipeSearchRequest(
    query: query ?? this.query,
    filter: filter ?? this.filter,
    maxMinutes: clearMinutes ? null : maxMinutes ?? this.maxMinutes,
    difficulty: clearDifficulty ? null : difficulty ?? this.difficulty,
    excludedIngredients: excludedIngredients ?? this.excludedIngredients,
  );

  factory RecipeSearchRequest.fromParameters(Map<String, String> params) {
    final minutes = int.tryParse(params['minutes'] ?? '');
    return RecipeSearchRequest(
      query: params['q'] ?? '',
      filter: RecipeSearchFilter.fromId(params['filter']),
      maxMinutes: minutes != null && minutes > 0 && minutes <= 960
          ? minutes
          : null,
      difficulty: RecipeDifficulty.values
          .where((value) => value.name == params['difficulty'])
          .firstOrNull,
      excludedIngredients: params['exclude'] ?? '',
    );
  }
  @override
  List<Object?> get props => [
    query,
    filter,
    maxMinutes,
    difficulty,
    excludedIngredients,
  ];
}
