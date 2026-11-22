import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../recipe_detail/models/recipe_detail.dart';
import '../services/kitchen_services.dart';

class RecipeToolsState {
  final bool busy;
  final String? message;
  final bool success;
  const RecipeToolsState({
    this.busy = false,
    this.message,
    this.success = false,
  });
}

class RecipeToolsCubit extends Cubit<RecipeToolsState> {
  final KitchenServices services;
  RecipeToolsCubit(this.services) : super(const RecipeToolsState());
  Future<void> _run(Future<void> Function() action, {String? message}) async {
    if (state.busy) return;
    emit(const RecipeToolsState(busy: true));
    try {
      await action();
      if (!isClosed) emit(RecipeToolsState(message: message, success: true));
    } catch (error) {
      if (!isClosed) {
        emit(
          RecipeToolsState(
            message: error is FormatException ? error.message.toString() : 'Chưa hoàn tất thao tác. Kiểm tra kết nối hoặc dùng Sao chép liên kết.',
          ),
        );
      }
    }
  }

  Future<void> download(RecipeDetail recipe) => _run(
    () => services.offline.download(recipe),
    message: 'Đã tải nội dung và ảnh để đọc offline.',
  );
  Future<void> share(String id, Rect origin) =>
      _run(() => services.sharing.share(id, origin));
  Future<void> copy(String id) => _run(
    () => services.sharing.copy(id),
    message: 'Đã sao chép liên kết công thức.',
  );
}
