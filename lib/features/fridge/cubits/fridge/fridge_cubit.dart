import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/fridge_service.dart';
import 'fridge_state.dart';

export 'fridge_state.dart';

class FridgeCubit extends Cubit<FridgeState> {
  final FridgeService service;
  Future<void>? _loadTask;
  Future<void> _pendingSave = Future.value();
  int _inventoryVersion = 0;
  List<String> _confirmedIds = const [];

  FridgeCubit({required this.service}) : super(const FridgeState());

  Future<void> loadFridge() {
    if (isClosed) return Future.value();
    return _loadTask ??= _loadFridge().whenComplete(() => _loadTask = null);
  }

  Future<void> _loadFridge() async {
    // Read sau write: không tải một snapshot cũ trong lúc đang lưu.
    await _pendingSave;
    if (isClosed) return;
    emit(state.copyWith(status: FridgeStatus.loading));
    try {
      final data = await service.fetchFridge();
      if (isClosed) return;
      _confirmedIds = data.selectedIds;
      emit(
        state.copyWith(
          status: FridgeStatus.success,
          data: data,
          selectedIds: data.selectedIds,
        ),
      );
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          state.copyWith(
            status: FridgeStatus.failure,
            errorMessage: 'Không tải được tủ lạnh. Vui lòng thử lại.',
          ),
        );
      }
    }
  }

  Future<void> toggleIngredient(String id) {
    if (isClosed) return Future.value();
    final loading = _loadTask;
    // Giữ ý định thao tác khi refresh; đối chiếu với response mới nhất sau đó.
    if (loading != null) return loading.then((_) => toggleIngredient(id));
    if (!(state.data?.ingredientsById.containsKey(id) ?? false)) {
      return Future.value();
    }
    final updated = [...state.selectedIds];
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    return _saveInventory(updated);
  }

  Future<void> removeIngredient(String id) {
    if (isClosed) return Future.value();
    final loading = _loadTask;
    if (loading != null) return loading.then((_) => removeIngredient(id));
    if (!state.selectedIds.contains(id)) return Future.value();
    return _saveInventory(
      state.selectedIds.where((item) => item != id).toList(),
    );
  }

  Future<void> clearIngredients() {
    if (isClosed) return Future.value();
    final loading = _loadTask;
    if (loading != null) return loading.then((_) => clearIngredients());
    if (state.selectedIds.isEmpty) return Future.value();
    return _saveInventory([]);
  }

  Future<void> _saveInventory(List<String> ids) {
    if (state.data == null) return Future.value();
    final version = ++_inventoryVersion;
    final snapshot = List<String>.unmodifiable(ids);
    emit(state.copyWith(selectedIds: snapshot, isSaving: true));
    _pendingSave = _pendingSave.then((_) async {
      try {
        await service.saveInventory(snapshot);
        _confirmedIds = snapshot;
        if (!isClosed && version == _inventoryVersion) {
          emit(state.copyWith(isSaving: false));
        }
      } catch (error, stack) {
        if (!isClosed) {
          addError(error, stack);
          if (version == _inventoryVersion) {
            emit(
              state.copyWith(
                selectedIds: _confirmedIds,
                isSaving: false,
                errorMessage: 'Chưa lưu được nguyên liệu. Vui lòng thử lại.',
              ),
            );
          }
        }
      }
    });
    return _pendingSave;
  }

  void searchIngredients(String query) {
    if (!isClosed) {
      emit(state.copyWith(query: query, errorMessage: state.errorMessage));
    }
  }

  void selectFilter(FridgeRecipeFilter filter) {
    if (!isClosed) {
      emit(state.copyWith(filter: filter, errorMessage: state.errorMessage));
    }
  }
}
