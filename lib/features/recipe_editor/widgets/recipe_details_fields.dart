import 'package:app_bep_xinh/core/widgets/app_selection_controls.dart';
import 'package:app_bep_xinh/core/tap/tap_extension.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_serving_selector.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';
import 'package:app_bep_xinh/core/widgets/app_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';
import '../models/recipe_draft.dart';
import '../validation/recipe_editor_validation.dart';

import 'package:app_bep_xinh/core/widgets/app_text_field.dart';

import 'recipe_editor_section.dart';
import 'recipe_editor_labels.dart';

class RecipeTitleField extends StatelessWidget {
  const RecipeTitleField({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        RecipeEditorCubit,
        RecipeEditorState,
        (String, String?, bool)
      >(
        selector: (state) =>
            (state.draft.title, state.errors['title'], state.isSubmitting),
        builder: (context, value) => AppTextField(
          fieldId: 'recipe_title',
          initialValue: value.$1,
          label: 'Tên món ăn',
          hint: 'Ví dụ: Cá hồi áp chảo bơ tỏi',
          error: value.$2,
          enabled: !value.$3,
          maxLength: RecipeEditorLimits.titleLength,
          onChanged: context.read<RecipeEditorCubit>().changeTitle,
        ),
      );
}

class RecipeDetailsFields extends StatelessWidget {
  const RecipeDetailsFields({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecipeEditorCubit, RecipeEditorState>(
        buildWhen: (previous, current) =>
            previous.draft.preparationMinutes !=
                current.draft.preparationMinutes ||
            previous.draft.cookingMinutes != current.draft.cookingMinutes ||
            previous.draft.servings != current.draft.servings ||
            previous.draft.difficulty != current.draft.difficulty ||
            previous.isSubmitting != current.isSubmitting ||
            previous.errors['preparation'] != current.errors['preparation'] ||
            previous.errors['cooking'] != current.errors['cooking'],
        builder: (context, state) {
          final cubit = context.read<RecipeEditorCubit>();
          return RecipeEditorSection(
            title: 'Thông số chế biến',

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        fieldId: 'recipe_preparation',
                        initialValue: state.draft.preparationMinutes,
                        label: 'Chuẩn bị (phút)',
                        hint: '15',
                        numeric: true,
                        maxLength: 3,
                        error: state.errors['preparation'],
                        enabled: !state.isSubmitting,
                        onChanged: cubit.changePreparation,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        fieldId: 'recipe_cooking',
                        initialValue: state.draft.cookingMinutes,
                        label: 'Nấu (phút)',
                        hint: '20',
                        numeric: true,
                        maxLength: 3,
                        error: state.errors['cooking'],
                        enabled: !state.isSubmitting,
                        onChanged: cubit.changeCooking,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AppServingSelector(
                  value: state.draft.servings,
                  max: RecipeEditorLimits.maxServings,
                  onChanged: state.isSubmitting
                      ? null
                      : (value) =>
                            cubit.changeServings(value - state.draft.servings),
                ),
                const SizedBox(height: 14),
                Text('Độ khó', style: AppTextStyles.labelMedium),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final difficulty in RecipeDifficulty.values)
                      AppChoiceChip(
                        label: difficulty.label,
                        selected: state.draft.difficulty == difficulty,
                        onSelected: state.isSubmitting
                            ? null
                            : (_) => context
                                  .onAppTap(
                                    () => cubit.selectDifficulty(difficulty),
                                    actionName:
                                        'recipe_difficulty_${difficulty.name}',
                                  )
                                  ?.call(),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}

class RecipeDescriptionField extends StatelessWidget {
  const RecipeDescriptionField({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        RecipeEditorCubit,
        RecipeEditorState,
        (String, String?, bool)
      >(
        selector: (state) => (
          state.draft.description,
          state.errors['description'],
          state.isSubmitting,
        ),
        builder: (context, value) => AppTextField(
          fieldId: 'recipe_description',
          initialValue: value.$1,
          label: 'Mô tả & cảm hứng',
          hint: 'Điều gì khiến món ăn này đặc biệt với bạn?',
          maxLength: RecipeEditorLimits.descriptionLength,
          minLines: 3,
          maxLines: 5,
          error: value.$2,
          enabled: !value.$3,
          onChanged: context.read<RecipeEditorCubit>().changeDescription,
        ),
      );
}

class RecipeMealFields extends StatelessWidget {
  const RecipeMealFields({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        RecipeEditorCubit,
        RecipeEditorState,
        (Set<RecipeMeal>, bool)
      >(
        selector: (state) => (state.draft.meals, state.isSubmitting),
        builder: (context, value) => AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionHeader(title: 'Thích hợp cho bữa ăn'),
              const SizedBox(height: 4),
              Text('Có thể chọn nhiều mục', style: AppTextStyles.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final meal in RecipeMeal.values)
                    AppFilterChip(
                      label: meal.label,
                      selected: value.$1.contains(meal),
                      onSelected: value.$2
                          ? null
                          : (_) => context
                                .onAppTap(
                                  () => context
                                      .read<RecipeEditorCubit>()
                                      .toggleMeal(meal),
                                  actionName: 'recipe_meal_${meal.name}',
                                )
                                ?.call(),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}

class RecipeStorageNotesField extends StatelessWidget {
  const RecipeStorageNotesField({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        RecipeEditorCubit,
        RecipeEditorState,
        (String, String?, bool)
      >(
        selector: (state) => (
          state.draft.storageNotes,
          state.errors['storageNotes'],
          state.isSubmitting,
        ),
        builder: (context, value) => RecipeEditorSection(
          title: 'Lưu ý & bí quyết bảo quản',
          child: AppTextField(
            fieldId: 'recipe_storage_notes',
            initialValue: value.$1,
            hint: 'Mẹo chọn nguyên liệu, cách bảo quản hoặc hâm nóng món ăn…',
            maxLength: RecipeEditorLimits.noteLength,
            minLines: 3,
            maxLines: 5,
            error: value.$2,
            enabled: !value.$3,
            onChanged: context.read<RecipeEditorCubit>().changeStorageNotes,
          ),
        ),
      );
}
