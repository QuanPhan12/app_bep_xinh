import 'package:app_bep_xinh/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'views/navigation_mobile_view.dart';
import 'views/navigation_tablet_view.dart';

/// Màn hình điều phối chính (Shell Route) của ứng dụng Bếp Xinh
/// Nhận StatefulNavigationShell từ GoRouter để quản lý BottomBar và các branches
class NavigationScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const NavigationScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: NavigationMobileView(navigationShell: navigationShell),
      tablet: NavigationTabletView(navigationShell: navigationShell),
    );
  }
}
