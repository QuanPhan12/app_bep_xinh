import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'views/navigation_tablet_view.dart';

/// Màn hình điều phối chính (Shell Route) của ứng dụng Bếp Xinh
/// Nhận StatefulNavigationShell từ GoRouter để quản lý BottomBar và các branches
class NavigationScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const NavigationScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    // Cùng một shell khi vượt mốc 600 để giữ navigation stack và state các tab.
    return NavigationTabletView(navigationShell: navigationShell);
  }
}
