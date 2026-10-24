import 'dart:async';

import 'package:app_bep_xinh/core/models/app_notification_type.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../../services/recipe_detail_service.dart';
import 'recipe_detail_state.dart';
export 'recipe_detail_state.dart';

class RecipeDetailCubit extends Cubit<RecipeDetailState> {
  final String recipeId;
  final RecipeDetailService service;
  final RecipeFavoritesService favorites;
  late final StreamSubscription<RecipeFavoriteChange> _subscription;
  final _latestFavorites = <String, bool>{};
  Future<void>? _loadTask;
  RecipeDetailCubit({
    required this.recipeId,
    required this.service,
    required this.favorites,
  }) : super(const RecipeDetailState()) {
    _subscription = favorites.changes.listen(
      (change) {
        if (isClosed) return;
        _latestFavorites[change.recipeId] = change.isFavorite;
        if (state.recipe?.id == change.recipeId) {
          emit(state.copyWith(isFavorite: change.isFavorite));
        }
      },
      onError: (Object error, StackTrace stack) {
        if (!isClosed) addError(error, stack);
      },
    );
  }
  Future<void> load() {
    if (isClosed || state.status == RecipeDetailStatus.ready) {
      return Future.value();
    }
    return _loadTask ??= _load().whenComplete(() => _loadTask = null);
  }

  Future<void> _load() async {
    emit(state.copyWith(status: RecipeDetailStatus.loading));
    try {
      final data = await service.fetchRecipe(recipeId);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RecipeDetailStatus.ready,
          recipe: data.recipe,
          servings: data.recipe.servings,
          isFavorite: _latestFavorites[data.recipe.id] ?? data.isFavorite,
          checkedIngredients: data.recipe.ingredients
              .where(
                (item) =>
                    data.availableIngredientIds.contains(item.ingredientId),
              )
              .map((item) => item.id)
              .toSet(),
        ),
      );
    } catch (error, stack) {
      if (isClosed) return;
      addError(error, stack);
      emit(
        state.copyWith(
          status: error is RecipeNotFoundException
              ? RecipeDetailStatus.notFound
              : RecipeDetailStatus.failure,
          message: error is RecipeNotFoundException
              ? 'Không tìm thấy công thức này.'
              : 'Không tải được công thức. Vui lòng thử lại.',
        ),
      );
    }
  }

  void changeServings(int value) {
    if (!isClosed && state.recipe != null) {
      emit(state.copyWith(servings: value.clamp(1, 50)));
    }
  }

  void selectTab(RecipeDetailTab tab) {
    if (!isClosed) emit(state.copyWith(tab: tab));
  }

  void toggleIngredient(String id) {
    if (isClosed ||
        !(state.recipe?.ingredients.any((item) => item.id == id) ?? false)) {
      return;
    }
    final updated = {...state.checkedIngredients};
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    emit(state.copyWith(checkedIngredients: updated));
  }

  void toggleAllIngredients() {
    if (isClosed || state.recipe == null) return;
    final ids = state.recipe!.ingredients.map((item) => item.id).toSet();
    emit(
      state.copyWith(
        checkedIngredients: state.checkedIngredients.containsAll(ids)
            ? {}
            : ids,
      ),
    );
  }

  Future<void> toggleFavorite() async {
    if (isClosed || state.recipe == null || state.savingFavorite) return;
    final value = !state.isFavorite;
    emit(state.copyWith(savingFavorite: true));
    try {
      await favorites.setFavorite(state.recipe!.id, value);
      if (!isClosed) {
        emit(state.copyWith(isFavorite: value, savingFavorite: false));
      }
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          state.copyWith(
            savingFavorite: false,
            message: 'Chưa lưu được món yêu thích. Vui lòng thử lại.',
            noticeType: AppNotificationType.error,
            noticeId: state.noticeId + 1,
          ),
        );
      }
    }
  }

  void startCooking() {
    if (!isClosed && state.recipe != null) {
      emit(
        state.copyWith(
          tab: RecipeDetailTab.steps,
          cookingStep: state.cookingStep ?? 0,
        ),
      );
    }
  }

  void previousStep() {
    if (!isClosed && state.cookingStep != null && state.cookingStep! > 0) {
      emit(state.copyWith(cookingStep: state.cookingStep! - 1));
    }
  }

  void nextStep() {
    if (isClosed || state.recipe == null || state.cookingStep == null) return;
    if (state.cookingStep == state.recipe!.steps.length - 1) {
      emit(
        state.copyWith(
          stopCooking: true,
          message: 'Bạn đã hoàn thành món ăn.',
          noticeType: AppNotificationType.success,
          noticeId: state.noticeId + 1,
        ),
      );
    } else {
      emit(state.copyWith(cookingStep: state.cookingStep! + 1));
    }
  }

  @override
  Future<void> close() async {
    final cancellation = _subscription.cancel();
    await super.close();
    await cancellation;
  }
}
