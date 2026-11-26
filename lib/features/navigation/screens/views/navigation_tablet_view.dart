import '../../../../sollume/shared/app_navigation_item.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/tap/app_tap_handler.dart';
import '../../../../core/widgets/app_appearance_picker.dart';
import '../../../../core/utils/app_layout.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../../../ai_chat/widgets/ai_chat_floating_layer.dart';

class NavigationTabletView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const NavigationTabletView({super.key, required this.navigationShell});
  @override
  Widget build(BuildContext context) {
    final extended = MediaQuery.sizeOf(context).width >= 1180;
    final useRail = AppLayout.useNavigationRail(context);
    void switchTab(int index) => navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
    return Scaffold(
      backgroundColor: context.colors.background,
      bottomNavigationBar: useRail
          ? null
          : AppBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTabSelected: switchTab,
              onCreateRecipe: () {
                context.push(PathRouter.recipeEditorScreen);
              },
            ),
      body: Row(
        children: [
          Offstage(
            offstage: !useRail,
            child: useRail
                ? Material(
                    color: context.colors.surface,
                    child: Container(
                      width: extended ? 224 : 100,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: context.colors.border,
                            width: .5,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24,
                                horizontal: 12,
                              ),
                              child: extended
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Bếp Xinh',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -1,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      PhosphorIconsRegular.forkKnife,
                                      color: AppColors.primary,
                                      size: 30,
                                    ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _RailItem(
                                      label: 'Trang chủ',
                                      icon: PhosphorIconsRegular.house,
                                      selected:
                                          navigationShell.currentIndex == 0,
                                      extended: extended,
                                      onTap: () => switchTab(0),
                                    ),
                                    _RailItem(
                                      label: 'Tìm kiếm',
                                      icon:
                                          PhosphorIconsRegular.magnifyingGlass,
                                      extended: extended,
                                      onTap: () {
                                        context.push(PathRouter.recipeSearch());
                                      },
                                    ),
                                    _RailItem(
                                      label: 'Tủ lạnh',
                                      icon: PhosphorIconsRegular.snowflake,
                                      selected:
                                          navigationShell.currentIndex == 1,
                                      extended: extended,
                                      onTap: () => switchTab(1),
                                    ),
                                    _RailItem(
                                      label: 'Bếp của tôi',
                                      icon: PhosphorIconsRegular.bookOpen,
                                      selected:
                                          navigationShell.currentIndex == 2,
                                      extended: extended,
                                      onTap: () => switchTab(2),
                                    ),
                                    _RailItem(
                                      label: 'Cá nhân',
                                      icon: PhosphorIconsRegular.userCircle,
                                      selected:
                                          navigationShell.currentIndex == 3,
                                      extended: extended,
                                      onTap: () => switchTab(3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const AppAppearancePicker(compact: true),
                            _RailItem(
                              label: 'Cài đặt',
                              icon: PhosphorIconsRegular.list,
                              extended: extended,
                              onTap: () {
                                context.push(PathRouter.settingsScreen);
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(child: AiChatFloatingLayer(child: navigationShell)),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected, extended;
  final VoidCallback onTap;
  const _RailItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.extended = false,
  });
  @override
  Widget build(BuildContext context) => AppNavigationItem(
    label: label,
    icon: icon,
    selectedIcon: switch (icon) {
      PhosphorIconsRegular.house => PhosphorIconsFill.house,
      PhosphorIconsRegular.snowflake => PhosphorIconsBold.snowflake,
      PhosphorIconsRegular.bookOpen => PhosphorIconsFill.bookOpen,
      PhosphorIconsRegular.userCircle => PhosphorIconsFill.userCircle,
      _ => icon,
    },
    selected: selected,
    collapsed: !extended,
    onTap: () =>
        AppTapHandler.handle(context, actionName: 'rail_$label', onTap: onTap),
  );
}
