import '../../kitchen/cubits/kitchen_list_cubit.dart';

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../ingredients/models/ingredient_catalog.dart';
import '../../ingredients/models/ingredient_quantity.dart';

class MealSummaryLine {
  final String name;
  final double? amount;
  final IngredientUnit? unit;
  final bool toTaste;
  const MealSummaryLine(this.name, this.amount, this.unit, this.toTaste);
  String get text =>
      '$name: ${formatIngredientQuantity(amount: amount, ratio: 1, unit: unit, toTaste: toTaste)}';
}

class MealPlannerCubit extends KitchenListCubit<MealPlanEntry> {
  final KitchenServices services;
  late DateTime weekStart;
  MealPlannerCubit(this.services) : super(services.meals) {
    final today = DateTime.now();
    weekStart = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));
  }
  List<MealPlanEntry> get weekEntries => state.items.where((e) {
    final date = kitchenDate(e.day);
    return !date.isBefore(weekStart) &&
        date.isBefore(weekStart.add(const Duration(days: 7)));
  }).toList();
  void moveWeek(int delta) {
    weekStart = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + delta * 7,
    );
    emit(
      KitchenListState(
        items: state.items,
        loading: state.loading,
        busy: state.busy,
        error: state.error,
      ),
    );
  }

  Future<List<MealSummaryLine>> summary() async {
    final grouped = <String, MealSummaryLine>{};
    for (final entry in weekEntries) {
      final recipe = (await services.details.fetchRecipe(entry.recipe.id))
          .recipe;
      for (final item in recipe.ingredients) {
        final key = item.ingredientId == null
            ? '${entry.id}/${item.id}'
            : '${item.ingredientId}/${item.unit?.id}/${item.toTaste}';
        final amount = item.amount == null
            ? null
            : item.amount! * entry.servings / recipe.servings;
        final previous = grouped[key];
        grouped[key] = MealSummaryLine(
          item.name,
          amount == null ? null : amount + (previous?.amount ?? 0),
          item.unit,
          item.toTaste,
        );
      }
    }
    return grouped.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<bool> copyDay(String from, String to) => run(() async {
    if (from == to) throw const FormatException('Chọn ngày khác để sao chép.');
    final entries = state.items.where((e) => e.day == from).toList();
    for (final entry in entries) {
      await repository.save(
        MealPlanEntry(
          id: sha256.convert(utf8.encode('$to/${entry.id}')).toString(),
          day: to,
          slot: entry.slot,
          recipe: entry.recipe,
          servings: entry.servings,
        ),
      );
    }
  });
}
