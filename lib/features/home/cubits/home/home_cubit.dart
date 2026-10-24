import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';

/// Cubit quản lý trạng thái của màn hình Trang chủ Bếp Xinh
class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  /// Chọn danh mục món ăn
  void selectCategory(String categoryId) {
    emit(state.copyWith(selectedCategory: categoryId));
  }

  /// Chuyển đổi trạng thái yêu thích của món ăn
  void toggleFavorite(String recipeId) {
    final updatedList = state.recipes.map((item) {
      if (item.id == recipeId) {
        return item.copyWith(isFavorite: !item.isFavorite);
      }
      return item;
    }).toList();

    emit(state.copyWith(recipes: updatedList));
  }

  /// Tải lại dữ liệu trang chủ
  Future<void> refreshHome() async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      emit(state.copyWith(status: HomeStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
