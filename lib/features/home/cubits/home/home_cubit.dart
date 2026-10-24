import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_bep_xinh/features/fridge/models/fridge_summary.dart';

import '../../services/home_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeService service;
  Future<void>? _loadTask;
  final Map<String, bool> _refreshFavorites = {};
  late final StreamSubscription<FridgeSummary> _summarySubscription;
  late final StreamSubscription<RecipeFavoriteChange> _favoriteSubscription;
  FridgeSummary? _latestSummary;
  int _summaryRevision = 0;

  HomeCubit({required this.service}) : super(const HomeState()) {
    _favoriteSubscription = service.favoriteChanges.listen(
      _onFavorite,
      onError: (Object error, StackTrace stack) {
        if (!isClosed) addError(error, stack);
      },
    );
    _summarySubscription = service.fridgeSummaries.listen(
      _onSummary,
      onError: (Object error, StackTrace stack) {
        if (!isClosed) addError(error, stack);
      },
    );
  }

  Future<void> loadHome() {
    if (isClosed) return Future.value();
    // Caller trùng cùng chờ request hiện tại; RefreshIndicator không kết thúc sớm.
    return _loadTask ??= _loadHome().whenComplete(() => _loadTask = null);
  }

  Future<void> _loadHome() async {
    _refreshFavorites.clear();
    final summaryRevision = _summaryRevision;
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      var data = await service.fetchHome();
      if (isClosed) return;
      // Chỉ bảo vệ write xảy ra trong request này; request sau vẫn tin server.
      if (_refreshFavorites.isNotEmpty) {
        data = data.withRecipes(
          data.recipes
              .map(
                (recipe) => _refreshFavorites.containsKey(recipe.id)
                    ? recipe.copyWith(isFavorite: _refreshFavorites[recipe.id])
                    : recipe,
              )
              .toList(),
        );
      }
      if (_summaryRevision != summaryRevision && _latestSummary != null) {
        data = data.withFridgeSummary(_latestSummary!);
      }
      final category =
          data.categories.any((item) => item.id == state.selectedCategory)
          ? state.selectedCategory
          : 'all';
      emit(
        state.copyWith(
          status: HomeStatus.success,
          data: data,
          selectedCategory: category,
        ),
      );
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          state.copyWith(
            status: HomeStatus.failure,
            errorMessage: 'Không tải được trang chủ. Vui lòng thử lại.',
          ),
        );
      }
    } finally {
      _refreshFavorites.clear();
    }
  }

  void _onFavorite(RecipeFavoriteChange change) {
    if (isClosed) return;
    if (_loadTask != null) {
      _refreshFavorites[change.recipeId] = change.isFavorite;
    }
    final data = state.data;
    if (data == null) return;
    emit(
      state.copyWith(
        data: data.withRecipes(
          data.recipes
              .map(
                (recipe) => recipe.id == change.recipeId
                    ? recipe.copyWith(isFavorite: change.isFavorite)
                    : recipe,
              )
              .toList(),
        ),
        errorMessage: state.errorMessage,
      ),
    );
  }

  void _onSummary(FridgeSummary summary) {
    if (isClosed) return;
    _latestSummary = summary;
    _summaryRevision++;
    final data = state.data;
    if (data != null && data.fridgeSummary != summary) {
      emit(
        state.copyWith(
          data: data.withFridgeSummary(summary),
          errorMessage: state.errorMessage,
        ),
      );
    }
  }

  Future<void> refreshHome() => loadHome();

  void selectCategory(String id) {
    if (isClosed) return;
    if (id == 'all' ||
        (state.data?.categories.any((category) => category.id == id) ??
            false)) {
      emit(
        state.copyWith(selectedCategory: id, errorMessage: state.errorMessage),
      );
    }
  }

  Future<void> toggleFavorite(String recipeId) async {
    if (isClosed || state.savingFavorites.contains(recipeId)) return;
    final matches = state.recipes.where((item) => item.id == recipeId);
    if (matches.isEmpty) return;
    final value = !matches.first.isFavorite;
    emit(state.copyWith(savingFavorites: {...state.savingFavorites, recipeId}));
    try {
      await service.setFavorite(recipeId, value);
      if (isClosed) return;
      if (_loadTask != null) _refreshFavorites[recipeId] = value;
      emit(
        state.copyWith(
          data: state.data!.withRecipes(
            state.recipes
                .map(
                  (item) => item.id == recipeId
                      ? item.copyWith(isFavorite: value)
                      : item,
                )
                .toList(),
          ),
          savingFavorites: {...state.savingFavorites}..remove(recipeId),
        ),
      );
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          state.copyWith(
            savingFavorites: {...state.savingFavorites}..remove(recipeId),
            errorMessage: 'Chưa lưu được món yêu thích. Vui lòng thử lại.',
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    // Không chờ HTTP trong close; chỉ hủy resource do Cubit sở hữu.
    final cancellation = Future.wait([
      _summarySubscription.cancel(),
      _favoriteSubscription.cancel(),
    ]);
    await super.close();
    await cancellation;
  }
}
