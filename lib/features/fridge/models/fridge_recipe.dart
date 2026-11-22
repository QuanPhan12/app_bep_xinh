import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';

import '../../ingredients/models/ingredient_catalog.dart';
import '../../recipes/models/recipe_content.dart';

class FridgeRecipe extends Equatable {
  final String id;
  final String title;
  final String description;
  final int minutes;
  final bool isVegetarian;
  final List<String> ingredientIds;
  final String? image;
  final Map<String, String> ingredientNames;

  const FridgeRecipe({
    required this.id,
    required this.title,
    required this.description,
    required this.minutes,
    required this.ingredientIds,
    this.isVegetarian = false,
    this.image,
    this.ingredientNames = const {},
  });

  List<String> missingIngredients(Iterable<String> selectedIds) {
    final selected = selectedIds is Set<String>
        ? selectedIds
        : selectedIds.toSet();
    return ingredientIds.where((id) => !selected.contains(id)).toList();
  }

  factory FridgeRecipe.fromJson(Map<String, dynamic> json) => FridgeRecipe(
    id: JsonReader(json).string('id'),
    title: JsonReader(json).string('title'),
    description: JsonReader(json)
        .string('description', fallback: '', allowEmpty: true),
    minutes: JsonReader(json).integer('minutes', min: 1),
    ingredientIds: JsonReader(json).strings('ingredientIds', allowEmpty: false),
    isVegetarian: JsonReader(json).boolean('isVegetarian'),
    image: JsonReader(json).optionalString('image'),
  );

  factory FridgeRecipe.fromPublished(
    Map<String, dynamic> json,
    IngredientCatalog catalog,
  ) {
    final content = RecipeContent.fromJson(json, catalog);
    final id = JsonReader(json).string('id');
    // Nguyên liệu tự nhập chưa có trong catalog luôn được tính là còn thiếu.
    final names = {
      for (final item in content.ingredients)
        item.ingredientId ?? 'custom:$id:${item.id}': item.name,
    };
    return FridgeRecipe(
      id: id,
      title: content.title,
      description: content.description,
      minutes: content.preparationMinutes + content.cookingMinutes,
      ingredientIds: List.unmodifiable(names.keys),
      ingredientNames: Map.unmodifiable(names),
      isVegetarian: content.categories.contains(RecipeCategory.vegetarian),
      image: content.cover?.source,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    minutes,
    isVegetarian,
    ingredientIds,
    image,
    ingredientNames,
  ];
}
