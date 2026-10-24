import 'package:equatable/equatable.dart';

import 'fridge_data.dart';

class FridgeSummary extends Equatable {
  final List<String> ingredientNames;
  final int readyRecipeCount;

  FridgeSummary({
    required List<String> ingredientNames,
    required this.readyRecipeCount,
  }) : ingredientNames = List.unmodifiable(ingredientNames);

  factory FridgeSummary.fromData(FridgeData data) => FridgeSummary(
    ingredientNames: data.ingredients
        .where((item) => data.selectedIds.contains(item.id))
        .map((item) => item.name)
        .toList(),
    readyRecipeCount: data.selectedIds.isEmpty
        ? 0
        : data.recipes
              .where(
                (recipe) => recipe.missingIngredients(data.selectedIds).isEmpty,
              )
              .length,
  );

  @override
  List<Object> get props => [ingredientNames, readyRecipeCount];
}
