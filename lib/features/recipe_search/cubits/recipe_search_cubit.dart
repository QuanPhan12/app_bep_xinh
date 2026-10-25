import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../models/recipe_search_request.dart';
import '../services/recipe_search_service.dart';
import 'recipe_search_state.dart';
export 'recipe_search_state.dart';

class RecipeSearchCubit extends Cubit<RecipeSearchState> {
  final RecipeSearchService service;
  final RecipeFavoritesService favorites;
  final Duration debounce;
  final _overrides = <String, bool>{};
  late final StreamSubscription<RecipeFavoriteChange> _subscription;
  Timer? _timer;
  int _generation = 0;

  RecipeSearchCubit({
    required this.service,
    required this.favorites,
    RecipeSearchRequest initialRequest = const RecipeSearchRequest(),
    this.debounce = const Duration(milliseconds: 300),
  }) : super(RecipeSearchState(request: initialRequest)) {
    _subscription = favorites.changes.listen(
      (change) {
        if (isClosed) return;
        _overrides[change.recipeId] = change.isFavorite;
        emit(state.copyWith(recipes: _apply(state.recipes)));
      },
      onError: (Object error, StackTrace stack) {
        if (!isClosed) addError(error, stack);
      },
    );
  }

  List<RecipeItem> _apply(List<RecipeItem> recipes) => recipes
      .map(
        (recipe) => recipe.copyWith(
          isFavorite: _overrides[recipe.id] ?? recipe.isFavorite,
        ),
      )
      .toList();

  void changeQuery(String query) {
    if (isClosed || state.request.query == query) return;
    _timer?.cancel();
    final generation = ++_generation;
    emit(
      state.copyWith(
        request: RecipeSearchRequest(
          query: query,
          filter: state.request.filter,
        ),
        status: RecipeSearchStatus.loading,
        recipes: [],
      ),
    );
    _timer = Timer(debounce, () => unawaited(_search(generation)));
  }

  Future<void> selectFilter(RecipeSearchFilter filter) {
    if (isClosed || state.request.filter == filter) return Future.value();
    emit(
      state.copyWith(
        request: RecipeSearchRequest(
          query: state.request.query,
          filter: filter,
        ),
      ),
    );
    return load();
  }

  Future<void> clearQuery() {
    if (isClosed) return Future.value();
    emit(
      state.copyWith(
        request: RecipeSearchRequest(filter: state.request.filter),
      ),
    );
    return load();
  }

  Future<void> load() {
    if (isClosed) return Future.value();
    _timer?.cancel();
    final generation = ++_generation;
    emit(state.copyWith(status: RecipeSearchStatus.loading, recipes: []));
    return _search(generation);
  }

  Future<void> _search(int generation) async {
    final request = state.request;
    try {
      final recipes = await service.search(request);
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          status: RecipeSearchStatus.ready,
          recipes: _apply(recipes),
        ),
      );
    } catch (error, stack) {
      if (isClosed || generation != _generation) return;
      addError(error, stack);
      emit(
        state.copyWith(
          status: RecipeSearchStatus.failure,
          message: 'Chưa tìm được món ăn. Vui lòng thử lại.',
        ),
      );
    }
  }

  Future<void> toggleFavorite(String id) async {
    if (isClosed || state.savingFavorites.contains(id)) return;
    final recipe = state.recipes.where((recipe) => recipe.id == id).firstOrNull;
    if (recipe == null) return;
    final value = !recipe.isFavorite;
    emit(state.copyWith(savingFavorites: {...state.savingFavorites, id}));
    try {
      await favorites.setFavorite(id, value);
      if (isClosed) return;
      _overrides[id] = value;
      emit(state.copyWith(recipes: _apply(state.recipes)));
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          state.copyWith(
            message: 'Chưa lưu được món yêu thích. Vui lòng thử lại.',
            noticeId: state.noticeId + 1,
          ),
        );
      }
    } finally {
      if (!isClosed) {
        emit(
          state.copyWith(
            savingFavorites: {...state.savingFavorites}..remove(id),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    ++_generation;
    await super.close();
    await _subscription.cancel();
  }
}
