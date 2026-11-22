import 'recipe_remix_fields.dart';

import 'package:app_bep_xinh/core/widgets/app_content_scroll_view.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';
import 'package:app_bep_xinh/core/widgets/app_adaptive_columns.dart';

import 'package:app_bep_xinh/core/widgets/app_feature_header.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';

import 'recipe_cover_field.dart';
import 'recipe_details_fields.dart';
import 'recipe_category_fields.dart';
import 'recipe_ingredients_fields.dart';
import 'recipe_steps_fields.dart';
import 'recipe_editor_labels.dart';
import 'recipe_editor_progress.dart';
import 'recipe_review.dart';

class RecipeEditorForm extends StatelessWidget {
  const RecipeEditorForm({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocSelector<RecipeEditorCubit, RecipeEditorState, RecipeEditorStep>(
    selector: (state) => state.step,
    builder: (context, step) => Column(
      children: [
        if (MediaQuery.viewInsetsOf(context).bottom == 0)
          const RecipeEditorProgress(),
        Expanded(
          child: AppContentScrollView(
            key: ValueKey('recipe_editor_${step.name}'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(16.w(context)),
            children: [
              if (MediaQuery.viewInsetsOf(context).bottom == 0)
                AppFeatureHeader(
                  eyebrow: 'CÔNG THỨC CỦA BẠN',
                  title: step.title,
                  description: step.description,
                  green: step == RecipeEditorStep.review,
                ),
              const SizedBox(height: 20),
              if (step == RecipeEditorStep.details ||
                  step == RecipeEditorStep.review)
                RecipeRemixFields(readOnly: step == RecipeEditorStep.review),
              ...switch (step) {
                RecipeEditorStep.details => const <Widget>[
                  AppAdaptiveColumns(
                    primary: AppCard(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          RecipeCoverField(),
                          SizedBox(height: 20),
                          RecipeTitleField(),
                          SizedBox(height: 20),
                          RecipeDescriptionField(),
                        ],
                      ),
                    ),
                    secondary: Column(
                      children: [
                        RecipeDetailsFields(),
                        SizedBox(height: 16),
                        RecipeCategoryFields(),
                        SizedBox(height: 16),
                        RecipeMealFields(),
                      ],
                    ),
                  ),
                ],
                RecipeEditorStep.ingredients => const <Widget>[
                  AppAdaptiveColumns(
                    primaryFlex: 1,
                    secondaryFlex: 2,
                    primary: RecipeIngredientSummary(),
                    secondary: RecipeIngredientsFields(),
                  ),
                ],
                RecipeEditorStep.instructions => const <Widget>[
                  RecipeStepsFields(),
                  SizedBox(height: 16),
                  RecipeStorageNotesField(),
                ],
                RecipeEditorStep.review => const <Widget>[RecipeReview()],
              },
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    ),
  );
}
