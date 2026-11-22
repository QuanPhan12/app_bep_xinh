import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/kitchen_entry.dart';
import '../services/kitchen_repository.dart';

class KitchenListState<T> {
  final List<T> items;
  final bool loading;
  final bool busy;
  final String? error;
  const KitchenListState({
    this.items = const [],
    this.loading = true,
    this.busy = false,
    this.error,
  });
}

class KitchenListCubit<T extends KitchenEntry>
    extends Cubit<KitchenListState<T>> {
  final KitchenRepository<T> repository;
  StreamSubscription<List<T>>? _subscription;
  KitchenListCubit(this.repository) : super(KitchenListState<T>());
  void load() {
    _subscription?.cancel();
    emit(KitchenListState(items: state.items, loading: true));
    try {
      _subscription = repository.watch().listen(
        (items) {
          if (!isClosed) {
            emit(
              KitchenListState(items: items, loading: false, busy: state.busy),
            );
          }
        },
        onError: (Object error, StackTrace stack) {
          if (!isClosed) {
            addError(error, stack);
            emit(
              KitchenListState(
                items: state.items,
                loading: false,
                error: 'Chưa tải được dữ liệu. Vui lòng thử lại.',
              ),
            );
          }
        },
      );
    } catch (error, stack) {
      addError(error, stack);
      emit(
        KitchenListState(
          items: state.items,
          loading: false,
          error: 'Phiên hoặc kết nối đã thay đổi. Vui lòng tải lại.',
        ),
      );
    }
  }

  Future<bool> run(Future<void> Function() action) async {
    if (isClosed || state.busy) return false;
    emit(KitchenListState(items: state.items, loading: false, busy: true));
    try {
      await action();
      if (isClosed) return false;
      emit(KitchenListState(items: state.items, loading: false));
      return true;
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          KitchenListState(
            items: state.items,
            loading: false,
            error: error is FormatException
                ? error.message.toString()
                : 'Chưa lưu được thay đổi. Kiểm tra kết nối và thử lại.',
          ),
        );
      }
      return false;
    }
  }

  Future<bool> save(T value) => run(() => repository.save(value));
  Future<bool> remove(String id) => run(() => repository.delete(id));
  Future<bool> update(String id, T Function(T) change) =>
      run(() => repository.update(id, change));
  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
