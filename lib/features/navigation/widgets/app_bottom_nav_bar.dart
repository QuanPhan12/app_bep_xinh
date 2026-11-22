import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/tap/app_tap_handler.dart';

/// Bốn điểm đến có nhãn; router sở hữu trạng thái được chọn.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  const AppBottomNavBar({
    super.key,
    this.currentIndex = 0,
    required this.onTabSelected,
  });
  static const labels = ['Trang chủ', 'Tủ lạnh', 'Bếp của tôi', 'Cá nhân'];
  static const icons = [
    PhosphorIconsRegular.house,
    PhosphorIconsRegular.snowflake,
    PhosphorIconsRegular.bookOpen,
    PhosphorIconsRegular.userCircle,
  ];
  static const selectedIcons = [
    PhosphorIconsFill.house,
    PhosphorIconsBold.snowflake,
    PhosphorIconsFill.bookOpen,
    PhosphorIconsFill.userCircle,
  ];
  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      border: Border(top: Divider.createBorderSide(context)),
    ),
    child: NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => AppTapHandler.handle(
        context,
        actionName: 'nav_tab_$index',
        onTap: () => onTabSelected(index),
      ),
      maintainBottomViewPadding: true,
      elevation: 0,
      destinations: [
        for (var i = 0; i < labels.length; i++)
          NavigationDestination(
            key: ValueKey('nav_item_$i'),
            icon: PhosphorIcon(icons[i]),
            selectedIcon: PhosphorIcon(selectedIcons[i]),
            label: labels[i],
          ),
      ],
    ),
  );
}
