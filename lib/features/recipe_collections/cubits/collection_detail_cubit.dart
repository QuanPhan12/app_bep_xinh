import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../recipe_detail/models/recipe_detail.dart';

class CollectionRecipeRow {
  final String id;
  final RecipeDetail? recipe;
  final bool failed;
  const CollectionRecipeRow(this.id, {this.recipe, this.failed = false});
}

class CollectionDetailState {
  final RecipeCollection? collection;
  final List<CollectionRecipeRow> rows;
  final bool loading, busy;
  final String? error;
  const CollectionDetailState({
    this.collection,
    this.rows = const [],
    this.loading = true,
    this.busy = false,
    this.error,
  });
}

class CollectionDetailCubit extends Cubit<CollectionDetailState> {
  final KitchenServices services;
  final String id;
  StreamSubscription<List<RecipeCollection>>? _subscription;
  int _generation = 0;
  CollectionDetailCubit(this.services, this.id)
    : super(const CollectionDetailState());
  void load() {
    _subscription?.cancel();
    _subscription = services.collections.watch().listen(
      _receive,
      onError: (Object _, StackTrace _) {
        if (!isClosed) {
          emit(
            CollectionDetailState(
              collection: state.collection,
              rows: state.rows,
              loading: false,
              error: 'Chưa tải được bộ sưu tập.',
            ),
          );
        }
      },
    );
  }

  Future<void> _receive(List<RecipeCollection> items) async {
    final collection = items.where((item) => item.id == id).firstOrNull;
    final generation = ++_generation;
    if (isClosed) return;
    if (collection == null) {
      emit(
        const CollectionDetailState(
          loading: false,
          error: 'Bộ sưu tập không còn tồn tại.',
        ),
      );
      return;
    }
    final cache = {
      for (final row in state.rows)
        if (row.recipe != null) row.id: row,
    };
    final rows = collection.recipeIds
        .map((id) => cache[id] ?? CollectionRecipeRow(id))
        .toList();
    emit(
      CollectionDetailState(
        collection: collection,
        rows: rows,
        loading: false,
        busy: state.busy,
      ),
    );
    // Tải theo nhóm nhỏ để bộ sưu tập dài không bắn hàng trăm request cùng lúc.
    for (var offset = 0; offset < rows.length; offset += 4) {
      await Future.wait(
        rows.skip(offset).take(4).map((row) async {
          if (row.recipe != null) return;
          CollectionRecipeRow next;
          try {
            next = CollectionRecipeRow(
              row.id,
              recipe: (await services.details.fetchRecipe(row.id)).recipe,
            );
          } catch (_) {
            next = CollectionRecipeRow(row.id, failed: true);
          }
          if (isClosed || generation != _generation) return;
          final updated = state.rows
              .map((value) => value.id == row.id ? next : value)
              .toList();
          emit(
            CollectionDetailState(
              collection: state.collection,
              rows: updated,
              loading: false,
              busy: state.busy,
            ),
          );
        }),
      );
      if (isClosed || generation != _generation) return;
    }
  }

  Future<void> _change(List<String> Function(List<String>) change) async {
    if (state.busy || state.collection == null) return;
    emit(
      CollectionDetailState(
        collection: state.collection,
        rows: state.rows,
        loading: false,
        busy: true,
      ),
    );
    try {
      await services.collections.update(
        id,
        (current) => RecipeCollection(
          id: id,
          name: current.name,
          recipeIds: change(current.recipeIds),
        ),
      );
      if (!isClosed) {
        emit(
          CollectionDetailState(
            collection: state.collection,
            rows: state.rows,
            loading: false,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          CollectionDetailState(
            collection: state.collection,
            rows: state.rows,
            loading: false,
            error: 'Chưa cập nhật được bộ sưu tập.',
          ),
        );
      }
    }
  }

  Future<void> add(String recipeId) =>
      _change((current) => {...current, recipeId}.toList());
  Future<void> remove(String recipeId) =>
      _change((current) => current.where((id) => id != recipeId).toList());
  @override
  Future<void> close() async {
    ++_generation;
    await _subscription?.cancel();
    await super.close();
  }
}
