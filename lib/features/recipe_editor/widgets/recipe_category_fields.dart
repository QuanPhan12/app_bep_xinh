import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/widgets/app_selection_controls.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';
import 'package:app_bep_xinh/core/widgets/app_section_header.dart';
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
        builder: (context, value) => AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(title: 'Danh mục món ăn'),
              const SizedBox(height: 4),
              Text(
                'Chọn các mục phù hợp để mọi người dễ tìm thấy món của bạn.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
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
