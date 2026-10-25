import 'dart:async';

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/tap/tap_extension.dart';
import 'package:flutter/material.dart';

class RecipeEditorMenu extends StatelessWidget {
  final String label;
  final bool enabled;
  final List<({String label, FutureOr<void> Function()? onTap})> actions;

  const RecipeEditorMenu({
    super.key,
    required this.label,
    required this.actions,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    tooltip: label,
    enabled: enabled,
    icon: const Icon(Icons.more_horiz, size: 22, color: AppColors.textTertiary),
    onSelected: (index) => context
        .onAppTap(actions[index].onTap, actionName: 'recipe_editor_menu_action')
        ?.call(),
    itemBuilder: (context) => [
      for (var index = 0; index < actions.length; index++)
        PopupMenuItem(
          value: index,
          enabled: actions[index].onTap != null,
          child: Text(actions[index].label),
        ),
    ],
  );
}
