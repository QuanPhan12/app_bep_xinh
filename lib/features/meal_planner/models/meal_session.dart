import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../kitchen/models/kitchen_entry.dart';
import '../../ingredients/models/ingredient_quantity.dart';

String mealKey(String value) => sha256.convert(utf8.encode(value)).toString();

class MealSession implements KitchenEntry {
  @override
  final String id;
  final MealPlanEntry plan;
  final String selectedRecipeId;
  final Map<String, int> steps;
  final List<String> done;
  final bool completed;
  final bool pantryConsumed;
  const MealSession({
    required this.id,
    required this.plan,
    required this.selectedRecipeId,
    this.steps = const {},
    this.done = const [],
    this.completed = false,
    this.pantryConsumed = false,
  });
  factory MealSession.start(MealPlanEntry meal) => MealSession(
    id: meal.id,
    plan: meal,
    selectedRecipeId: meal.recipe.id,
    steps: {for (final dish in meal.dishes) dish.recipe.id: 0},
  );
  factory MealSession.fromJson(String id, Map<String, dynamic> json) =>
      MealSession(
        id: id,
        plan: MealPlanEntry.fromJson(
          id,
          Map<String, dynamic>.from(json['plan'] as Map),
        ),
        selectedRecipeId: json['selectedRecipeId'] as String,
        steps: Map<String, int>.from(json['steps'] as Map),
        done: List<String>.from(json['done'] as List),
        completed: json['completed'] as bool,
        pantryConsumed: json['pantryConsumed'] as bool,
      );
  MealSession copyWith({
    String? selectedRecipeId,
    Map<String, int>? steps,
    List<String>? done,
    bool? completed,
    bool? pantryConsumed,
  }) => MealSession(
    id: id,
    plan: plan,
    selectedRecipeId: selectedRecipeId ?? this.selectedRecipeId,
    steps: Map.unmodifiable(steps ?? this.steps),
    done: List.unmodifiable(done ?? this.done),
    completed: completed ?? this.completed,
    pantryConsumed: pantryConsumed ?? this.pantryConsumed,
  );
  @override
  Map<String, dynamic> toJson() {
    final ids = plan.dishes.map((d) => d.recipe.id).toSet();
    if (!ids.contains(selectedRecipeId) ||
        steps.keys.toSet().difference(ids).isNotEmpty ||
        ids.difference(steps.keys.toSet()).isNotEmpty ||
        steps.values.any((v) => v < 0 || v > 19) ||
        done.toSet().length != done.length ||
        done.any((id) => !ids.contains(id)) ||
        (completed && done.length != ids.length) ||
        (pantryConsumed && !completed)) {
      throw const FormatException('Tiến độ bữa ăn không hợp lệ.');
    }
    return {
      'plan': {...plan.toJson(), 'schemaVersion': plan.schemaVersion},
      'selectedRecipeId': selectedRecipeId,
      'steps': steps,
      'done': done,
      'completed': completed,
      'pantryConsumed': pantryConsumed,
    };
  }
}

class ShoppingLine {
  final String key, name, quantity;
  final bool checked;
  String get displayQuantity => formatWholeStoredIngredientQuantity(quantity);
  const ShoppingLine({
    required this.key,
    required this.name,
    required this.quantity,
    this.checked = false,
  });
  ShoppingLine toggle() =>
      ShoppingLine(key: key, name: name, quantity: quantity, checked: !checked);
  Map<String, dynamic> toJson() => {
    'key': kitchenKey(key),
    'name': kitchenText(name, 80),
    'quantity': kitchenText(quantity, 100, empty: true),
    'checked': checked,
  };
  factory ShoppingLine.fromJson(Map<String, dynamic> json) => ShoppingLine(
    key: kitchenKey(json['key']),
    name: kitchenText(json['name'], 80),
    quantity: kitchenText(json['quantity'], 100, empty: true),
    checked: json['checked'] as bool,
  );
}

class ShoppingBatch implements KitchenEntry {
  @override
  final String id;
  final String title;
  final List<ShoppingLine> lines;
  const ShoppingBatch({
    required this.id,
    required this.title,
    required this.lines,
  });
  factory ShoppingBatch.fromJson(String id, Map<String, dynamic> json) =>
      ShoppingBatch(
        id: id,
        title: kitchenText(json['title'], 80),
        lines: (jsonDecode(json['linesJson'] as String) as List)
            .map(
              (e) => ShoppingLine.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      );
  @override
  Map<String, dynamic> toJson() {
    if (lines.length > 180 ||
        lines.map((e) => e.key).toSet().length != lines.length) {
      throw const FormatException('Danh sách đi chợ không hợp lệ.');
    }
    final encoded = jsonEncode(lines.map((e) => e.toJson()).toList());
    if (utf8.encode(encoded).length > 100000) {
      throw const FormatException('Danh sách quá dài.');
    }
    return {'title': kitchenText(title, 80), 'linesJson': encoded};
  }
}
