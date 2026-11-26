import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';

import '../../recipes/widgets/recipe_section.dart';

import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/material.dart';

class RecipeEditorSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const RecipeEditorSection({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return RecipeSection(title: title, action: action, child: child);
  }
}

class RecipeEditorRemoveAction extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const RecipeEditorRemoveAction({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      child: AppTap(
        actionName: 'recipe_editor_remove',
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 44,
          child: Icon(
            PhosphorIconsRegular.x,
            size: 15,
            color: context.colors.textTertiary,
          ),
        ),
      ),
    ),
  );
}
