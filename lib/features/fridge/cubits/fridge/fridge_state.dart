import 'package:equatable/equatable.dart';

import '../../models/fridge_data.dart';

import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';

import '../../models/fridge_recipe.dart';

enum FridgeRecipeFilter { all, quick, vegetarian }

enum FridgeStatus { initial, loading, success, failure }

class FridgeState extends Equatable {
  final FridgeStatus status;
  final FridgeData? data;
  final List<String> selectedIds;
  final String query;
  final FridgeRecipeFilter filter;
  final bool isSaving;
  final String? errorMessage;

  const FridgeState({
    this.status = FridgeStatus.initial,
    this.data,
    this.selectedIds = const [],
    this.query = '',
    this.filter = FridgeRecipeFilter.all,
    this.isSaving = false,
    this.errorMessage,
  });

  List<Ingredient> get ingredients => data?.ingredients ?? const [];
  List<FridgeRecipe> get recipes => data?.recipes ?? const [];
  bool get hasCatalog => ingredients.isNotEmpty;

  String ingredientName(String id) => data?.ingredientsById[id]?.name ?? id;

  List<Ingredient> get selectedIngredients => [
    for (final id in selectedIds) ?data?.ingredientsById[id],
  ];

  List<Ingredient> get visibleIngredients {
    return ingredients
        .where((ingredient) => ingredient.matches(query))
        .toList();
  }

  bool _matchesFilter(FridgeRecipe recipe) => switch (filter) {
    FridgeRecipeFilter.all => true,
    FridgeRecipeFilter.quick => recipe.minutes <= 15,
    FridgeRecipeFilter.vegetarian => recipe.isVegetarian,
  };

  List<FridgeRecipe> get readyRecipes => selectedIds.isEmpty
      ? []
      : recipes
            .where(
              (recipe) =>
                  _matchesFilter(recipe) &&
                  recipe.missingIngredients(selectedIds).isEmpty,
            )
            .toList();

  List<FridgeRecipe> get almostReadyRecipes => selectedIds.isEmpty
      ? []
      : recipes
            .where(
              (recipe) =>
                  _matchesFilter(recipe) &&
                  recipe.missingIngredients(selectedIds).length == 1,
            )
            .toList();

  FridgeState copyWith({
    FridgeStatus? status,
    FridgeData? data,
    List<String>? selectedIds,
    String? query,
    FridgeRecipeFilter? filter,
    bool? isSaving,
    String? errorMessage,
  }) => FridgeState(
    status: status ?? this.status,
    data: data ?? this.data,
    selectedIds: selectedIds == null
        ? this.selectedIds
        : List.unmodifiable(selectedIds),
    query: query ?? this.query,
    filter: filter ?? this.filter,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    status,
    data,
    selectedIds,
    query,
    filter,
    isSaving,
    errorMessage,
  ];
}
