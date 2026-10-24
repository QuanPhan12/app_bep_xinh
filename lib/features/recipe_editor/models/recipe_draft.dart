import 'dart:typed_data';

import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';

import 'package:equatable/equatable.dart';

enum RecipeDifficulty { easy, medium, hard }

class RecipeCover extends Equatable {
  final String id;
  final String name;
  final Uint8List bytes;

  RecipeCover({required this.id, required this.name, required Uint8List bytes})
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  // Không so sánh lại toàn bộ ảnh mỗi lần gõ vào form.
  @override
  List<Object> get props => [id];
}

/// id nhận diện dòng form; ingredientId nhận diện nguyên liệu trong danh mục.
/// Tên/nhãn đơn vị là snapshot hiển thị, đối chiếu dùng ID.
class RecipeIngredientDraft extends Equatable {
  final String id;
  final String? ingredientId;
  final String name;
  final double? amount;
  final IngredientUnit? unit;
  final bool toTaste;
  final String note;
  const RecipeIngredientDraft({
    required this.id,
    this.ingredientId,
    required this.name,
    this.amount,
    this.unit,
    this.toTaste = false,
    this.note = '',
  });

  String? get unitId => unit?.id;
  String get quantityLabel {
    if (toTaste) return 'Vừa đủ';
    final value = amount;
    if (value == null) return '';
    final text = value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toString().replaceAll('.', ',');
    return '$text ${unit?.label ?? ''}'.trim();
  }

  RecipeIngredientDraft withId(String value) => RecipeIngredientDraft(
    id: value,
    ingredientId: ingredientId,
    name: name,
    amount: amount,
    unit: unit,
    toTaste: toTaste,
    note: note,
  );

  RecipeIngredientDraft normalized() => RecipeIngredientDraft(
    id: id,
    ingredientId: ingredientId,
    name: name.trim(),
    amount: toTaste ? null : amount,
    unit: toTaste ? null : unit,
    toTaste: toTaste,
    note: note.trim(),
  );

  Map<String, dynamic> toJson() => {
    'ingredientId': ingredientId,
    'name': name.trim(),
    'amount': toTaste ? null : amount,
    'unitId': toTaste ? null : unitId,
    'toTaste': toTaste,
    'note': note.trim(),
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
  ];
}

class RecipeStepDraft extends Equatable {
  final String id;
  final String instruction;
  const RecipeStepDraft({required this.id, this.instruction = ''});

  RecipeStepDraft withInstruction(String value) =>
      RecipeStepDraft(id: id, instruction: value);

  @override
  List<Object> get props => [id, instruction];
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

  RecipeDraft({
    this.title = '',
    this.cover,
    this.preparationMinutes = '15',
    this.cookingMinutes = '20',
    this.servings = 2,
    this.difficulty = RecipeDifficulty.easy,
    List<RecipeIngredientDraft> ingredients = const [],
    List<RecipeStepDraft> steps = const [RecipeStepDraft(id: 'step_0')],
  }) : ingredients = List.unmodifiable(ingredients),
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
  }) => RecipeDraft(
    title: title ?? this.title,
    cover: removeCover ? null : cover ?? this.cover,
    preparationMinutes: preparationMinutes ?? this.preparationMinutes,
    cookingMinutes: cookingMinutes ?? this.cookingMinutes,
    servings: servings ?? this.servings,
    difficulty: difficulty ?? this.difficulty,
    ingredients: ingredients ?? this.ingredients,
    steps: steps ?? this.steps,
  );

  RecipeDraft normalized() => copyWith(
    title: title.trim(),
    preparationMinutes: preparationMinutes.trim(),
    cookingMinutes: cookingMinutes.trim(),
    ingredients: ingredients.map((item) => item.normalized()).toList(),
    steps: steps
        .map((item) => item.withInstruction(item.instruction.trim()))
        .toList(),
  );

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
  ];
}
