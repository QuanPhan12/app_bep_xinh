import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_bottom_nav_bar.dart';
import '../../../../core/router/app_router.dart';
import '../../../ai_chat/widgets/ai_chat_floating_layer.dart';

/// Giao diện điều hướng đáy dành cho thiết bị Mobile trong ShellRoute
class NavigationMobileView extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const NavigationMobileView({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: AiChatFloatingLayer(child: navigationShell),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onCreateRecipe: () {
          context.push(PathRouter.recipeEditorScreen);
        },
        onTabSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
