import 'dart:math';

import '../../ingredients/models/ingredient_catalog.dart';
import '../../ingredients/models/ingredient_quantity.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../recipe_detail/models/recipe_detail.dart';
import '../models/meal_session.dart';

String? baseUnit(String? unit) => switch (unit) {
  'kg' => 'g',
  'l' => 'ml',
  _ => unit,
};
double unitFactor(String? unit) => unit == 'kg' || unit == 'l' ? 1000 : 1;

class MealIngredient {
  final String key, name;
  final String? ingredientId;
  final IngredientUnit? unit;
  final double? amount;
  final bool toTaste;
  const MealIngredient({
    required this.key,
    required this.name,
    this.ingredientId,
    this.unit,
    this.amount,
    this.toTaste = false,
  });
  String quantity([double? value]) {
    // Chỉ làm tròn khi hiển thị; phép tính khẩu phần và trừ kho giữ lượng thật.
    return formatIngredientQuantity(
      amount: value ?? amount,
      unit: unit,
      toTaste: toTaste,
      wholeNumbers: true,
    );
  }
}

class PantryDeduction {
  final PantryLot lot;
  final double amount;
  const PantryDeduction(this.lot, this.amount);
  String get quantity =>
      formatWholeStoredIngredientQuantity('$amount ${lot.unitId}');
}

class MealIngredients {
  static List<MealIngredient> aggregate(
    MealPlanEntry meal,
    Map<String, RecipeDetail> recipes,
  ) {
    final result = <String, MealIngredient>{};
    for (final dish in meal.dishes) {
      final recipe = recipes[dish.recipe.id];
      if (recipe == null) {
        throw const FormatException('Một món không còn khả dụng.');
      }
      for (final item in recipe.ingredients) {
        // Nguyên liệu tự nhập và lượng chưa xác định không được suy ra từ tên giống nhau.
        final specified =
            !item.toTaste && item.amount != null && item.unit != null;
        final unit = baseUnit(item.unit?.id);
        final key = mealKey(
          '${item.ingredientId ?? 'custom:${recipe.id}:${item.id}'}/$unit/${specified ? 'number' : 'unknown:${recipe.id}:${item.id}'}',
        );
        final previous = result[key];
        result[key] = MealIngredient(
          key: key,
          name: item.name,
          ingredientId: item.ingredientId,
          toTaste: item.toTaste,
          unit: unit == item.unit?.id
              ? item.unit
              : IngredientUnit(id: unit!, label: unit),
          amount: specified
              ? (previous?.amount ?? 0) +
                    item.amount! *
                        meal.servings /
                        recipe.servings *
                        unitFactor(item.unit?.id)
              : null,
        );
      }
    }
    return result.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  static List<PantryDeduction> deductions(
    List<MealIngredient> ingredients,
    List<PantryLot> pantry,
    DateTime today,
  ) {
    final used = <String, double>{};
    for (final line in ingredients) {
      if (line.ingredientId == null ||
          line.amount == null ||
          line.unit == null ||
          line.toTaste) {
        continue;
      }
      var need = line.amount!;
      final matching =
          pantry
              .where(
                (lot) =>
                    lot.ingredientId == line.ingredientId &&
                    lot.amount != null &&
                    !lot.isExpired(today) &&
                    baseUnit(lot.unitId) == line.unit!.id,
              )
              .toList()
            ..sort(
              (a, b) =>
                  (a.expiresOn ?? '9999').compareTo(b.expiresOn ?? '9999'),
            );
      for (final lot in matching) {
        final factor = unitFactor(lot.unitId);
        final available = max(0.0, lot.amount! - (used[lot.id] ?? 0));
        final take = min(available, need / factor);
        if (take > 0) {
          used[lot.id] = (used[lot.id] ?? 0) + take;
          need = max(0, need - take * factor);
        }
      }
    }
    return [
      for (final lot in pantry)
        if ((used[lot.id] ?? 0) > 0) PantryDeduction(lot, used[lot.id]!),
    ];
  }

  static List<ShoppingLine> missing(
    MealPlanEntry meal,
    List<MealIngredient> ingredients,
    List<PantryLot> pantry,
    DateTime today,
  ) {
    final deductionsByLot = deductions(ingredients, pantry, today);
    return [
      for (final line in ingredients)
        if (!meal.preparedKeys.contains(line.key)) ...[
          if (line.amount == null || line.toTaste)
            ShoppingLine(
              key: line.key,
              name: line.name,
              quantity: line.toTaste ? 'Vừa đủ' : 'Kiểm tra số lượng',
            )
          else if (line.amount! -
                  deductionsByLot
                      .where(
                        (d) =>
                            d.lot.ingredientId == line.ingredientId &&
                            baseUnit(d.lot.unitId) == line.unit?.id,
                      )
                      .fold<double>(
                        0,
                        (sum, d) => sum + d.amount * unitFactor(d.lot.unitId),
                      ) >
              0.000001)
            ShoppingLine(
              key: line.key,
              name: line.name,
              quantity: line.quantity(
                max(
                  0,
                  line.amount! -
                      deductionsByLot
                          .where(
                            (d) =>
                                d.lot.ingredientId == line.ingredientId &&
                                baseUnit(d.lot.unitId) == line.unit?.id,
                          )
                          .fold<double>(
                            0,
                            (sum, d) =>
                                sum + d.amount * unitFactor(d.lot.unitId),
                          ),
                ),
              ),
            ),
        ],
    ];
  }
}
