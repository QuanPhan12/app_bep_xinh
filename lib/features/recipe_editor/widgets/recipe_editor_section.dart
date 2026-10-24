import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/widgets/app_section_header.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/cupertino.dart';
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 20),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title, action: action),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
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
        child: const SizedBox(
          width: 32,
          height: 44,
          child: Icon(
            CupertinoIcons.xmark,
            size: 15,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    ),
  );
}
