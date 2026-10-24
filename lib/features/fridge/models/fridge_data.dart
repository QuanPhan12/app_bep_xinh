import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';

import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';

import 'fridge_recipe.dart';

class FridgeData extends Equatable {
  final List<Ingredient> ingredients;
  final List<FridgeRecipe> recipes;
  final List<String> selectedIds;
  late final Map<String, Ingredient> ingredientsById = Map.unmodifiable({
    for (final ingredient in ingredients) ingredient.id: ingredient,
  });

  FridgeData({
    required List<Ingredient> ingredients,
    required List<FridgeRecipe> recipes,
    required List<String> selectedIds,
  }) : ingredients = List.unmodifiable(ingredients),
       recipes = List.unmodifiable(recipes),
       selectedIds = List.unmodifiable(selectedIds);

  FridgeData withInventory(List<String> ids) =>
      FridgeData(ingredients: ingredients, recipes: recipes, selectedIds: ids);

  factory FridgeData.fromJson(
    Map<String, dynamic> json, {
    required List<Ingredient> ingredients,
  }) {
    final reader = JsonReader(json);
    final knownIds = ingredients.map((item) => item.id).toSet();
    final recipes = reader
        .objects('recipes')
        .map(FridgeRecipe.fromJson)
        .toList();
    requireUniqueIds(ingredients.map((item) => item.id), 'ingredients');
    requireUniqueIds(recipes.map((item) => item.id), 'recipes');
    if (recipes.any(
      (recipe) => recipe.ingredientIds.any((id) => !knownIds.contains(id)),
    )) {
      throw const FormatException('Unknown recipe ingredient');
    }
    return FridgeData(
      ingredients: ingredients,
      recipes: recipes,
      selectedIds: reader
          .strings('selectedIds')
          .where(knownIds.contains)
          .toSet()
          .toList(),
    );
  }

  @override
  List<Object> get props => [ingredients, recipes, selectedIds];
}
