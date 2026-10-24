import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:flutter/material.dart';

import 'recipe_cover_field.dart';
import 'recipe_details_fields.dart';
import 'recipe_ingredients_fields.dart';
import 'recipe_steps_fields.dart';

class RecipeEditorForm extends StatelessWidget {
  const RecipeEditorForm({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('recipe_editor_form'),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: EdgeInsets.all(16.w(context)),
    children: [
      const RecipeCoverField(),
      SizedBox(height: 20.h(context)),
      const RecipeTitleField(),
      SizedBox(height: 20.h(context)),
      const RecipeDetailsFields(),
      SizedBox(height: 16.h(context)),
      const RecipeIngredientsFields(),
      SizedBox(height: 16.h(context)),
      const RecipeStepsFields(),
      SizedBox(height: 12.h(context)),
    ],
  );
}
