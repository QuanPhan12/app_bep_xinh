import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_bottom_nav_bar.dart';

/// Giao diện điều hướng đáy dành cho thiết bị Mobile trong ShellRoute
class NavigationMobileView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const NavigationMobileView({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTabSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        onAddTap: () {
          context.showInfo(
            'Tính năng Đăng tải công thức mới đang được cập nhật!',
            title: 'Đăng món',
          );
        },
      ),
    );
  }
}
