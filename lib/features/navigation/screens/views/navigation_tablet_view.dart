import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_bottom_nav_bar.dart';

/// Giao diện điều hướng đáy dành cho thiết bị Tablet trong ShellRoute
class NavigationTabletView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const NavigationTabletView({
    super.key,
    required this.navigationShell,
  });

  static const double _maxTabletContentWidth = 680.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: _maxTabletContentWidth,
          ),
          child: AppBottomNavBar(
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
        ),
      ),
    );
  }
}
