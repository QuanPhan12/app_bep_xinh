import 'recipe_section.dart';

import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class RecipeNotes extends StatelessWidget {
  final String title;
  final String text;
  const RecipeNotes({super.key, required this.title, required this.text});
  @override
  Widget build(BuildContext context) => RecipeSection(
    title: title,
    child: Text(text, style: AppTextStyles.bodyMedium.copyWith(height: 1.65)),
  );
}
