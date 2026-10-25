import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_quantity.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_content.dart';

export 'package:app_bep_xinh/features/recipes/models/recipe_content.dart';

class RecipeIngredientDraft extends Equatable {
  final String id;
  final String? ingredientId;
  final String name;
  final double? amount;
  final IngredientUnit? unit;
  final bool toTaste;
  final String note;
  final String groupId;
  const RecipeIngredientDraft({
    required this.id,
    this.ingredientId,
    required this.name,
    this.amount,
    this.unit,
    this.toTaste = false,
    this.note = '',
    this.groupId = 'main',
  });

  String? get unitId => unit?.id;
  String get quantityLabel =>
      formatIngredientQuantity(amount: amount, unit: unit, toTaste: toTaste);

  RecipeIngredientDraft withId(String value) => RecipeIngredientDraft(
    id: value,
    ingredientId: ingredientId,
    name: name,
    amount: amount,
    unit: unit,
    toTaste: toTaste,
    note: note,
    groupId: groupId,
  );

  RecipeIngredientDraft inGroup(String value) => RecipeIngredientDraft(
    id: id,
    ingredientId: ingredientId,
    name: name,
    amount: amount,
    unit: unit,
    toTaste: toTaste,
    note: note,
    groupId: value,
  );

  RecipeIngredientDraft normalized() => RecipeIngredientDraft(
    id: id,
    ingredientId: ingredientId,
    name: name.trim(),
    amount: toTaste ? null : amount,
    unit: toTaste ? null : unit,
    toTaste: toTaste,
    note: note.trim(),
    groupId: groupId,
  );

  Map<String, dynamic> toJson() => {
    'ingredientId': ingredientId,
    'name': name.trim(),
    'amount': toTaste ? null : amount,
    'unitId': toTaste ? null : unitId,
    'toTaste': toTaste,
    'note': note.trim(),
    'groupId': groupId,
  };

  @override
  List<Object?> get props => [
    id,
    ingredientId,
    name,
    amount,
    unit,
    toTaste,
    note,
    groupId,
  ];
}

class RecipeStepDraft extends Equatable {
  final String id;
  final String instruction;
  final String title;
  final String minutes;
  final String tip;
  final RecipeCover? photo;
  const RecipeStepDraft({
    required this.id,
    this.instruction = '',
    this.title = '',
    this.minutes = '',
    this.tip = '',
    this.photo,
  });

  RecipeStepDraft copyWith({
    String? instruction,
    String? title,
    String? minutes,
    String? tip,
    RecipeCover? photo,
    bool removePhoto = false,
  }) => RecipeStepDraft(
    id: id,
    instruction: instruction ?? this.instruction,
    title: title ?? this.title,
    minutes: minutes ?? this.minutes,
    tip: tip ?? this.tip,
    photo: removePhoto ? null : photo ?? this.photo,
  );

  RecipeStepDraft withInstruction(String value) => copyWith(instruction: value);

  RecipeStep toRecipeStep() => RecipeStep(
    id: id,
    title: title.trim(),
    instruction: instruction.trim(),
    minutes: minutes.trim().isEmpty ? null : int.parse(minutes),
    tip: tip.trim(),
    photo: photo,
  );

  @override
  List<Object?> get props => [id, instruction, title, minutes, tip, photo];
}

class RecipeDraft extends Equatable {
  final String title;
  final RecipeCover? cover;
  final String preparationMinutes;
  final String cookingMinutes;
  final int servings;
  final RecipeDifficulty difficulty;
  final List<RecipeIngredientDraft> ingredients;
  final List<RecipeStepDraft> steps;
  final String description;
  final String storageNotes;
  final Set<RecipeMeal> meals;
  final Set<RecipeCategory> categories;
  final List<RecipeIngredientGroup> ingredientGroups;

  RecipeDraft({
    this.title = '',
    this.cover,
    this.preparationMinutes = '15',
    this.cookingMinutes = '20',
    this.servings = 2,
    this.difficulty = RecipeDifficulty.easy,
    this.description = '',
    this.storageNotes = '',
    Set<RecipeMeal> meals = const {},
    Set<RecipeCategory> categories = const {},
    List<RecipeIngredientGroup> ingredientGroups = const [
      RecipeIngredientGroup(id: 'main', name: 'Nguyên liệu chính'),
      RecipeIngredientGroup(id: 'seasoning', name: 'Gia vị & nước sốt'),
    ],
    List<RecipeIngredientDraft> ingredients = const [],
    List<RecipeStepDraft> steps = const [RecipeStepDraft(id: 'step_0')],
  }) : ingredients = List.unmodifiable(ingredients),
       meals = Set.unmodifiable(meals),
       categories = Set.unmodifiable(categories),
       ingredientGroups = List.unmodifiable(ingredientGroups),
       steps = List.unmodifiable(steps);

  RecipeDraft copyWith({
    String? title,
    RecipeCover? cover,
    bool removeCover = false,
    String? preparationMinutes,
    String? cookingMinutes,
    int? servings,
    RecipeDifficulty? difficulty,
    List<RecipeIngredientDraft>? ingredients,
    List<RecipeStepDraft>? steps,
    String? description,
    String? storageNotes,
    Set<RecipeMeal>? meals,
    Set<RecipeCategory>? categories,
    List<RecipeIngredientGroup>? ingredientGroups,
  }) => RecipeDraft(
    title: title ?? this.title,
    cover: removeCover ? null : cover ?? this.cover,
    preparationMinutes: preparationMinutes ?? this.preparationMinutes,
    cookingMinutes: cookingMinutes ?? this.cookingMinutes,
    servings: servings ?? this.servings,
    difficulty: difficulty ?? this.difficulty,
    ingredients: ingredients ?? this.ingredients,
    steps: steps ?? this.steps,
    description: description ?? this.description,
    storageNotes: storageNotes ?? this.storageNotes,
    meals: meals ?? this.meals,
    categories: categories ?? this.categories,
    ingredientGroups: ingredientGroups ?? this.ingredientGroups,
  );

  RecipeDraft normalized() => copyWith(
    title: title.trim(),
    preparationMinutes: preparationMinutes.trim(),
    cookingMinutes: cookingMinutes.trim(),
    description: description.trim(),
    storageNotes: storageNotes.trim(),
    ingredientGroups: ingredientGroups
        .map(
          (group) =>
              RecipeIngredientGroup(id: group.id, name: group.name.trim()),
        )
        .toList(),
    ingredients: ingredients.map((item) => item.normalized()).toList(),
    steps: steps
        .map(
          (item) => item.copyWith(
            instruction: item.instruction.trim(),
            title: item.title.trim(),
            minutes: item.minutes.trim(),
            tip: item.tip.trim(),
          ),
        )
        .toList(),
  );

  /// Convert a completed form to the same content used by detail and cooking.
  RecipeContent toRecipeContent() {
    final value = normalized();
    return RecipeContent(
      title: value.title,
      description: value.description,
      cover: value.cover,
      preparationMinutes: int.parse(value.preparationMinutes),
      cookingMinutes: int.parse(value.cookingMinutes),
      servings: value.servings,
      difficulty: value.difficulty,
      meals: value.meals,
      categories: value.categories,
      storageNotes: value.storageNotes,
      ingredientGroups: value.ingredientGroups,
      ingredients: value.ingredients
          .map(
            (item) => RecipeIngredient(
              id: item.id,
              ingredientId: item.ingredientId,
              name: item.name,
              amount: item.amount,
              unit: item.unit,
              toTaste: item.toTaste,
              note: item.note,
              groupId: item.groupId,
            ),
          )
          .toList(),
      steps: value.steps.map((step) => step.toRecipeStep()).toList(),
    );
  }

  @override
  List<Object?> get props => [
    title,
    cover,
    preparationMinutes,
    cookingMinutes,
    servings,
    difficulty,
    ingredients,
    steps,
    description,
    storageNotes,
    meals,
    categories,
    ingredientGroups,
  ];
}
