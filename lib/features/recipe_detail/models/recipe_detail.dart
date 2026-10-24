import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_quantity.dart';

class RecipeDetailIngredient extends Equatable {
  final String id;
  final String? ingredientId;
  final String name;
  final double? amount;
  final IngredientUnit? unit;
  final String note;
  final bool toTaste;
  const RecipeDetailIngredient({
    required this.id,
    this.ingredientId,
    required this.name,
    this.amount,
    this.unit,
    this.note = '',
    this.toTaste = false,
  });
  String quantity(double ratio) => formatIngredientQuantity(
    amount: amount,
    ratio: ratio,
    unit: unit,
    toTaste: toTaste,
  );

  factory RecipeDetailIngredient.fromJson(
    Map<String, dynamic> json,
    IngredientCatalog catalog,
  ) {
    final reader = JsonReader(json);
    final ingredientId = reader.optionalString('ingredientId');
    final known = catalog.byId[ingredientId];
    if (ingredientId != null && known == null) {
      throw const FormatException('Unknown ingredient');
    }
    final toTaste = reader.boolean('toTaste');
    final unitId = reader.optionalString('unitId');
    final unit = catalog.unitsById[unitId];
    final amount = toTaste ? null : reader.number('amount');
    if (!toTaste &&
        (amount! <= 0 ||
            unit == null ||
            (known != null && !known.unitIds.contains(unitId)))) {
      throw const FormatException('Invalid ingredient quantity');
    }
    return RecipeDetailIngredient(
      id: reader.string('id'),
      ingredientId: ingredientId,
      name: known?.name ?? reader.string('name'),
      amount: amount,
      unit: toTaste ? null : unit,
      note: reader.string('note', fallback: '', allowEmpty: true),
      toTaste: toTaste,
    );
  }
  @override
  List<Object?> get props => [
    id,
    ingredientId,
    name,
    amount,
    unit,
    note,
    toTaste,
  ];
}

class RecipeDetailStep extends Equatable {
  final String id;
  final String instruction;
  final int? minutes;
  const RecipeDetailStep({
    required this.id,
    required this.instruction,
    this.minutes,
  });
  factory RecipeDetailStep.fromJson(Map<String, dynamic> json) =>
      RecipeDetailStep(
        id: JsonReader(json).string('id'),
        instruction: JsonReader(json).string('instruction'),
        minutes: json['minutes'] == null
            ? null
            : JsonReader(json).integer('minutes', min: 1),
      );
  @override
  List<Object?> get props => [id, instruction, minutes];
}

class RecipeDetail extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? image;
  final String author;
  final int preparationMinutes;
  final int cookingMinutes;
  final int servings;
  final String difficulty;
  final double? rating;
  final int? calories;
  final bool isFavorite;
  final List<RecipeDetailIngredient> ingredients;
  final List<RecipeDetailStep> steps;
  RecipeDetail({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    required this.author,
    required this.preparationMinutes,
    required this.cookingMinutes,
    required this.servings,
    required this.difficulty,
    this.rating,
    this.calories,
    this.isFavorite = false,
    required List<RecipeDetailIngredient> ingredients,
    required List<RecipeDetailStep> steps,
  }) : ingredients = List.unmodifiable(ingredients),
       steps = List.unmodifiable(steps);

  factory RecipeDetail.fromJson(
    Map<String, dynamic> json,
    IngredientCatalog catalog,
  ) {
    final reader = JsonReader(json);
    final ingredients = reader
        .objects('ingredients')
        .map((item) => RecipeDetailIngredient.fromJson(item, catalog))
        .toList();
    final steps = reader
        .objects('steps')
        .map(RecipeDetailStep.fromJson)
        .toList();
    requireUniqueIds(ingredients.map((item) => item.id), 'recipe ingredients');
    requireUniqueIds(steps.map((item) => item.id), 'recipe steps');
    final servings = reader.integer('servings', min: 1);
    if (ingredients.isEmpty || steps.isEmpty || servings > 50) {
      throw const FormatException('Invalid recipe detail');
    }
    return RecipeDetail(
      id: reader.string('id'),
      title: reader.string('title'),
      description: reader.string('description'),
      image: reader.optionalString('image'),
      author: reader.string('author'),
      preparationMinutes: reader.integer('preparationMinutes'),
      cookingMinutes: reader.integer('cookingMinutes', min: 1),
      servings: servings,
      difficulty: reader.string('difficulty'),
      rating: json['rating'] == null ? null : reader.number('rating', max: 5),
      calories: reader.optionalInteger('calories'),
      isFavorite: reader.boolean('isFavorite'),
      ingredients: ingredients,
      steps: steps,
    );
  }
  @override
  List<Object?> get props => [
    id,
    title,
    description,
    image,
    author,
    preparationMinutes,
    cookingMinutes,
    servings,
    difficulty,
    rating,
    calories,
    isFavorite,
    ingredients,
    steps,
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
