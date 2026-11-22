import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/core/utils/search_utils.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_quantity.dart';

import 'recipe_image.dart';
import 'recipe_category.dart';
import 'recipe_limits.dart';

export 'recipe_image.dart';
export 'recipe_category.dart';
export 'recipe_limits.dart';

enum RecipeDifficulty {
  easy,
  medium,
  hard;

  static RecipeDifficulty parse(String value) => switch (value) {
    'easy' || 'Dễ' || 'Dễ làm' => RecipeDifficulty.easy,
    'medium' || 'Vừa' || 'Trung bình' => RecipeDifficulty.medium,
    'hard' || 'Khó' || 'Công phu' => RecipeDifficulty.hard,
    _ => throw const FormatException('Invalid difficulty'),
  };
}

enum RecipeMeal { breakfast, lunch, dinner, snack, gathering, weekend }

class RecipeIngredientGroup extends Equatable {
  final String id;
  final String name;
  const RecipeIngredientGroup({required this.id, required this.name});
  factory RecipeIngredientGroup.fromJson(Map<String, dynamic> json) =>
      RecipeIngredientGroup(
        id: JsonReader(json).string('id'),
        name: _text(json, 'name', RecipeLimits.groupNameLength, required: true),
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  @override
  List<Object> get props => [id, name];
}

class RecipeIngredient extends Equatable {
  final String id;
  final String? ingredientId;
  final String name;
  final double? amount;
  final IngredientUnit? unit;
  final String note;
  final bool toTaste;
  final String groupId;
  const RecipeIngredient({
    required this.id,
    this.ingredientId,
    required this.name,
    this.amount,
    this.unit,
    this.note = '',
    this.toTaste = false,
    this.groupId = 'main',
  });

  String quantity(double ratio) => formatIngredientQuantity(
    amount: amount,
    ratio: ratio,
    unit: unit,
    toTaste: toTaste,
  );

  String quantityForServings(int servings, int originalServings) {
    final originalAmount = amount;
    return formatIngredientQuantity(
      amount: originalAmount == null
          ? null
          : originalAmount * servings / originalServings,
      unit: unit,
      toTaste: toTaste,
      wholeNumbers: true,
    );
  }

  factory RecipeIngredient.fromJson(
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
    final amount = toTaste
        ? null
        : reader.number(
            'amount',
            max: RecipeLimits.maxIngredientAmount.toDouble(),
          );
    if (!toTaste &&
        (amount! <= 0 ||
            unit == null ||
            (known != null && !known.unitIds.contains(unitId)))) {
      throw const FormatException('Invalid ingredient quantity');
    }
    return RecipeIngredient(
      id: reader.string('id'),
      ingredientId: ingredientId,
      name: _text(
        {...json, 'name': json['name'] ?? known?.name},
        'name',
        RecipeLimits.ingredientNameLength,
        required: true,
      ),
      amount: amount,
      unit: toTaste ? null : unit,
      note: _text(json, 'note', RecipeLimits.ingredientNoteLength),
      toTaste: toTaste,
      groupId: reader.string('groupId', fallback: 'main'),
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'ingredientId': ingredientId,
    'name': name,
    'amount': toTaste ? null : amount,
    'unitId': toTaste ? null : unit?.id,
    'note': note,
    'toTaste': toTaste,
    'groupId': groupId,
  };
  @override
  List<Object?> get props => [
    id,
    ingredientId,
    name,
    amount,
    unit,
    note,
    toTaste,
    groupId,
  ];
}

class RecipeStep extends Equatable {
  final String id;
  final String title;
  final String instruction;
  final int? minutes;
  final String tip;
  final RecipeImage? photo;
  const RecipeStep({
    required this.id,
    required this.instruction,
    this.title = '',
    this.minutes,
    this.tip = '',
    this.photo,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final minutes = json['minutes'] == null
        ? null
        : reader.integer('minutes', min: 1);
    if (minutes != null && minutes > 720) {
      throw const FormatException('Invalid step duration');
    }
    return RecipeStep(
      id: reader.string('id'),
      instruction: _text(
        json,
        'instruction',
        RecipeLimits.instructionLength,
        required: true,
      ),
      title: _text(json, 'title', RecipeLimits.stepTitleLength),
      minutes: minutes,
      tip: _text(json, 'tip', RecipeLimits.noteLength),
      photo: _image(json['photo']),
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'instruction': instruction,
    'minutes': minutes,
    'tip': tip,
    'photo': photo?.toJson(),
  };
  @override
  List<Object?> get props => [id, title, instruction, minutes, tip, photo];
}

/// The recipe authored by the form. Identity, author and rating are server metadata.
class RecipeContent extends Equatable {
  final String title;
  final bool isBanner;
  final String description;
  final RecipeImage? cover;
  final int preparationMinutes;
  final int cookingMinutes;
  final int servings;
  final RecipeDifficulty difficulty;
  final Set<RecipeMeal> meals;
  final Set<RecipeCategory> categories;
  final String storageNotes;
  final List<RecipeIngredientGroup> ingredientGroups;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  RecipeContent({
    required this.title,
    this.isBanner = false,
    this.description = '',
    this.cover,
    required this.preparationMinutes,
    required this.cookingMinutes,
    required this.servings,
    required this.difficulty,
    Set<RecipeMeal> meals = const {},
    Set<RecipeCategory> categories = const {},
    this.storageNotes = '',
    required List<RecipeIngredientGroup> ingredientGroups,
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
  }) : categories = Set.unmodifiable(categories),
       meals = Set.unmodifiable(meals),
       ingredientGroups = List.unmodifiable(ingredientGroups),
       ingredients = List.unmodifiable(ingredients),
       steps = List.unmodifiable(steps);

  factory RecipeContent.fromJson(
    Map<String, dynamic> json,
    IngredientCatalog catalog,
  ) {
    final reader = JsonReader(json);
    final groups = json.containsKey('ingredientGroups')
        ? reader
              .objects('ingredientGroups')
              .map(RecipeIngredientGroup.fromJson)
              .toList()
        : const [RecipeIngredientGroup(id: 'main', name: 'Nguyên liệu chính')];
    final ingredients = reader
        .objects('ingredients')
        .map((item) => RecipeIngredient.fromJson(item, catalog))
        .toList();
    final steps = reader.objects('steps').map(RecipeStep.fromJson).toList();
    requireUniqueIds(groups.map((group) => group.id), 'ingredient groups');
    requireUniqueIds(ingredients.map((item) => item.id), 'recipe ingredients');
    requireUniqueIds(steps.map((step) => step.id), 'recipe steps');
    final ingredientKeys = ingredients.map(
      (item) => item.ingredientId == null
          ? 'custom:${searchKey(item.name)}'
          : 'catalog:${item.ingredientId}',
    );
    requireUniqueIds(ingredientKeys, 'recipe ingredient references');
    final groupIds = groups.map((group) => group.id).toSet();
    if (groups.isEmpty ||
        groups.length > RecipeLimits.groups ||
        ingredients.isEmpty ||
        ingredients.length > RecipeLimits.ingredients ||
        steps.isEmpty ||
        steps.length > RecipeLimits.steps ||
        ingredients.any((item) => !groupIds.contains(item.groupId))) {
      throw const FormatException('Invalid recipe structure');
    }
    final preparation = reader.integer('preparationMinutes');
    final cooking = reader.integer('cookingMinutes', min: 1);
    final servings = reader.integer('servings', min: 1);
    if (preparation > 240 ||
        cooking > 720 ||
        servings > RecipeLimits.maxServings) {
      throw const FormatException('Invalid recipe times or servings');
    }
    final meals = json.containsKey('meals')
        ? reader
              .strings('meals')
              .map(
                (name) =>
                    RecipeMeal.values
                        .where((meal) => meal.name == name)
                        .firstOrNull ??
                    (throw const FormatException('Invalid meal')),
              )
              .toSet()
        : <RecipeMeal>{};
    final difficulty = RecipeDifficulty.parse(reader.string('difficulty'));
    final legacyImage = reader.optionalString('image');
    return RecipeContent(
      title: _text(json, 'title', RecipeLimits.titleLength, required: true),
      isBanner: reader.boolean('isBanner'),
      description: _text(json, 'description', RecipeLimits.descriptionLength),
      cover: json['cover'] != null
          ? _image(json['cover'])
          : legacyImage == null
          ? null
          : RecipeImage.asset(id: legacyImage, assetPath: legacyImage),
      preparationMinutes: preparation,
      cookingMinutes: cooking,
      servings: servings,
      difficulty: difficulty,
      meals: meals,
      categories: json.containsKey('categories')
          ? reader.strings('categories').map(RecipeCategory.parse).toSet()
          : {},
      storageNotes: _text(json, 'storageNotes', RecipeLimits.noteLength),
      ingredientGroups: groups,
      ingredients: ingredients,
      steps: steps,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'isBanner': isBanner,
    'description': description,
    'cover': cover?.toJson(),
    'preparationMinutes': preparationMinutes,
    'cookingMinutes': cookingMinutes,
    'servings': servings,
    'difficulty': difficulty.name,
    'meals': RecipeMeal.values
        .where(meals.contains)
        .map((meal) => meal.name)
        .toList(),
    'categories': RecipeCategory.values
        .where(categories.contains)
        .map((value) => value.id)
        .toList(),
    'storageNotes': storageNotes,
    'ingredientGroups': ingredientGroups
        .map((group) => group.toJson())
        .toList(),
    'ingredients': ingredients.map((item) => item.toJson()).toList(),
    'steps': steps.map((step) => step.toJson()).toList(),
  };
  @override
  List<Object?> get props => [
    title,
    isBanner,
    description,
    cover,
    preparationMinutes,
    cookingMinutes,
    servings,
    difficulty,
    meals,
    categories,
    storageNotes,
    ingredientGroups,
    ingredients,
    steps,
  ];
}

String _text(
  Map<String, dynamic> json,
  String key,
  int maxLength, {
  bool required = false,
}) {
  final value = JsonReader(json)
      .string(key, fallback: required ? null : '', allowEmpty: !required)
      .trim();
  if (value.length > maxLength) throw FormatException('Text too long: $key');
  return value;
}

RecipeImage? _image(Object? value) {
  if (value == null) return null;
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid image');
  }
  return RecipeImage.fromJson(value);
}
