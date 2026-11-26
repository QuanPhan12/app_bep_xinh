import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';

import 'recipe_editor_section.dart';

class RecipeEditorTip extends StatelessWidget {
  final String title;
  final String message;
  const RecipeEditorTip({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => RecipeEditorSection(
    title: title,
    child: Text(message, style: AppTextStyles.bodySmall),
  );
}
