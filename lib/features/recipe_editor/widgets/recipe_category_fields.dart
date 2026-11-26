import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/widgets/app_selection_controls.dart';

import 'recipe_editor_section.dart';

import 'package:app_bep_xinh/features/recipes/models/recipe_category.dart';
import 'package:app_bep_xinh/features/recipes/presentation/recipe_labels.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';

class RecipeCategoryFields extends StatelessWidget {
  const RecipeCategoryFields({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        RecipeEditorCubit,
        RecipeEditorState,
        (Set<RecipeCategory>, bool)
      >(
        selector: (state) => (state.draft.categories, state.isSubmitting),
        builder: (context, value) => RecipeEditorSection(
          title: 'Danh mục món ăn',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final category in RecipeCategory.values)
                    AppFilterChip(
                      key: ValueKey('recipe_category_${category.id}'),
                      label: category.label,
                      selected: value.$1.contains(category),
                      onSelected: value.$2
                          ? null
                          : (_) => context
                                .read<RecipeEditorCubit>()
                                .toggleCategory(category),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}
