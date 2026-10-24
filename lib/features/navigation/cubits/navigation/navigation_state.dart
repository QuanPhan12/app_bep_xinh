import 'package:equatable/equatable.dart';

/// Các tab chính của ứng dụng Bếp Xinh
enum NavigationTab {
  home, // Trang chủ (index 0)
  fridge, // Tủ lạnh thông minh (index 1)
  cart, // Đi chợ / Giỏ hàng (index 2)
  profile, // Cá nhân (index 3)
}

/// State đại diện cho trạng thái của Feature Navigation
class NavigationState extends Equatable {
  final int currentIndex;

  const NavigationState({
    this.currentIndex = 0,
  });

  NavigationTab get currentTab {
    switch (currentIndex) {
      case 0:
        return NavigationTab.home;
      case 1:
        return NavigationTab.fridge;
      case 2:
        return NavigationTab.cart;
      case 3:
        return NavigationTab.profile;
      default:
        return NavigationTab.home;
    }
  }

  NavigationState copyWith({
    int? currentIndex,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => [currentIndex];
}
