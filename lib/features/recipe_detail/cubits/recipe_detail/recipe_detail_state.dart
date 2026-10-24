import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/models/app_notification_type.dart';

import '../../models/recipe_detail.dart';

enum RecipeDetailStatus { initial, loading, ready, failure, notFound }

enum RecipeDetailTab { ingredients, steps }

class RecipeDetailState extends Equatable {
  final RecipeDetailStatus status;
  final RecipeDetail? recipe;
  final int servings;
  final bool isFavorite;
  final bool savingFavorite;
  final Set<String> checkedIngredients;
  final RecipeDetailTab tab;
  final int? cookingStep;
  final String? message;
  final int noticeId;
  final AppNotificationType noticeType;
  const RecipeDetailState({
    this.status = RecipeDetailStatus.initial,
    this.recipe,
    this.servings = 2,
    this.isFavorite = false,
    this.savingFavorite = false,
    this.checkedIngredients = const {},
    this.tab = RecipeDetailTab.ingredients,
    this.cookingStep,
    this.message,
    this.noticeId = 0,
    this.noticeType = AppNotificationType.info,
  });
  double get quantityRatio => servings / (recipe?.servings ?? servings);
  RecipeDetailState copyWith({
    RecipeDetailStatus? status,
    RecipeDetail? recipe,
    int? servings,
    bool? isFavorite,
    bool? savingFavorite,
    Set<String>? checkedIngredients,
    RecipeDetailTab? tab,
    int? cookingStep,
    bool stopCooking = false,
    String? message,
    int? noticeId,
    AppNotificationType? noticeType,
  }) => RecipeDetailState(
    status: status ?? this.status,
    recipe: recipe ?? this.recipe,
    servings: servings ?? this.servings,
    isFavorite: isFavorite ?? this.isFavorite,
    savingFavorite: savingFavorite ?? this.savingFavorite,
    checkedIngredients: checkedIngredients == null
        ? this.checkedIngredients
        : Set.unmodifiable(checkedIngredients),
    tab: tab ?? this.tab,
    cookingStep: stopCooking ? null : cookingStep ?? this.cookingStep,
    message: message,
    noticeId: noticeId ?? this.noticeId,
    noticeType: noticeType ?? this.noticeType,
  );
  @override
  List<Object?> get props => [
    status,
    recipe,
    servings,
    isFavorite,
    savingFavorite,
    checkedIngredients,
    tab,
    cookingStep,
    message,
    noticeId,
    noticeType,
  ];
}
