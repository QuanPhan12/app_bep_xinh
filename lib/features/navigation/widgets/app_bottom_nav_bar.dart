import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/tap/app_tap_handler.dart';

/// Bốn tab và lối tắt đăng món ở giữa; router sở hữu trạng thái được chọn.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreateRecipe;
  const AppBottomNavBar({
    super.key,
    this.currentIndex = 0,
    required this.onTabSelected,
    required this.onCreateRecipe,
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
      selectedIndex: currentIndex < 2 ? currentIndex : currentIndex + 1,
      onDestinationSelected: (index) => AppTapHandler.handle(
        context,
        actionName: index == 2
            ? 'nav_create_recipe'
            : 'nav_tab_${index < 2 ? index : index - 1}',
        onTap: () {
          // Đăng món mở route riêng để giữ tab và stack đang xem khi quay lại.
          if (index == 2) {
            onCreateRecipe();
          } else {
            onTabSelected(index < 2 ? index : index - 1);
          }
        },
      ),
      maintainBottomViewPadding: true,
      elevation: 0,
      destinations: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i == 2)
            NavigationDestination(
              key: const ValueKey('nav_create_recipe'),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PhosphorIcon(
                  PhosphorIconsBold.plus,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              label: 'Đăng món',
              tooltip: 'Đăng món',
            ),
          NavigationDestination(
            key: ValueKey('nav_item_$i'),
            icon: PhosphorIcon(icons[i]),
            selectedIcon: PhosphorIcon(selectedIcons[i]),
            label: labels[i],
          ),
        ],
      ],
    ),
  );
}
