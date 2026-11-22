import '../../recipes/models/recipe_remix.dart';

import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_content.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_author.dart';

export 'package:app_bep_xinh/features/recipes/models/recipe_content.dart';
export 'package:app_bep_xinh/features/recipes/models/recipe_author.dart';

typedef RecipeDetailIngredient = RecipeIngredient;
typedef RecipeDetailStep = RecipeStep;

class RecipeDetail extends Equatable {
  final RecipeRemix? remix;
  final String? contentHash;
  final String id;
  final RecipeAuthor author;
  final RecipeContent content;
  final double? rating;
  final int? calories;
  final bool isFavorite;
  const RecipeDetail({
    this.remix,
    this.contentHash,
    required this.id,
    required this.author,
    required this.content,
    this.rating,
    this.calories,
    this.isFavorite = false,
  });

  String get title => content.title;
  String get description => content.description;
  RecipeImage? get cover => content.cover;
  String? get image => content.cover?.assetPath;
  int get preparationMinutes => content.preparationMinutes;
  int get cookingMinutes => content.cookingMinutes;
  int get servings => content.servings;
  RecipeDifficulty get difficulty => content.difficulty;
  Set<RecipeMeal> get meals => content.meals;
  String get storageNotes => content.storageNotes;
  List<RecipeIngredientGroup> get ingredientGroups => content.ingredientGroups;
  List<RecipeIngredient> get ingredients => content.ingredients;
  List<RecipeStep> get steps => content.steps;

  factory RecipeDetail.fromJson(
    Map<String, dynamic> json,
    IngredientCatalog catalog,
  ) {
    final reader = JsonReader(json);
    return RecipeDetail(
      remix: json['remix'] == null
          ? null
          : RecipeRemix.fromJson(
              Map<String, dynamic>.from(json['remix'] as Map),
            ),
      contentHash: reader.optionalString('contentHash'),
      id: reader.string('id'),
      author: RecipeAuthor.read(json['author']),
      content: RecipeContent.fromJson(json, catalog),
      rating: json['rating'] == null ? null : reader.number('rating', max: 5),
      calories: reader.optionalInteger('calories'),
      isFavorite: reader.boolean('isFavorite'),
    );
  }
  @override
  List<Object?> get props => [
    id,
    remix,
    contentHash,
    author,
    content,
    rating,
    calories,
    isFavorite,
  ];
}

class RecipeDetailData {
  final RecipeDetail recipe;
  final bool isFavorite;
  final Set<String> availableIngredientIds;
  RecipeDetailData({
    required this.recipe,
    required this.isFavorite,
    required Set<String> availableIngredientIds,
  }) : availableIngredientIds = Set.unmodifiable(availableIngredientIds);
}
