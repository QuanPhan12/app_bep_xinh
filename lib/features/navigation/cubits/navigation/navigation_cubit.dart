import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_state.dart';

/// Cubit quản lý điều hướng giữa các tab chính của ứng dụng Bếp Xinh
class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavigationState());

  /// Chuyển đổi tab điều hướng
  void changeTab(int index) {
    if (state.currentIndex != index) {
      emit(state.copyWith(currentIndex: index));
    }
  }

  /// Chuyển tab bằng Enum NavigationTab
  void selectTab(NavigationTab tab) {
    changeTab(tab.index);
  }
}
