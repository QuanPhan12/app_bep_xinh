import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_bottom_nav_bar.dart';

/// Giao diện điều hướng đáy dành cho thiết bị Tablet trong ShellRoute
class NavigationTabletView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const NavigationTabletView({super.key, required this.navigationShell});

  static const double _maxTabletContentWidth = AppLayout.formMaxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxTabletContentWidth),
          child: AppBottomNavBar(
            currentIndex: navigationShell.currentIndex,
            onTabSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            onAddTap: () {
              context.push(PathRouter.recipeEditorScreen);
            },
          ),
        ),
      ),
    );
  }
}
