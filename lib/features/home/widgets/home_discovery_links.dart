import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'home_action_scope.dart';

class HomeDiscoveryLinks extends StatelessWidget {
  const HomeDiscoveryLinks({super.key});
  @override
  Widget build(BuildContext context) {
    final actions = HomeActionScope.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final item in [
            (
              'Trong 30 phút',
              PhosphorIconsRegular.clock,
              actions.openQuickRecipes,
              'home_quick_recipes',
            ),
            (
              'Từ tủ lạnh',
              PhosphorIconsRegular.snowflake,
              actions.openFridge,
              'home_fridge_recipes',
            ),
            (
              'Đang theo dõi',
              PhosphorIconsRegular.users,
              actions.openFollowing,
              'home_following_recipes',
            ),
          ])
            TextButton.icon(
              key: ValueKey(item.$4),
              onPressed: item.$3,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              icon: Icon(item.$2, size: 18),
              label: Text(item.$1),
            ),
        ],
      ),
    );
  }
}
