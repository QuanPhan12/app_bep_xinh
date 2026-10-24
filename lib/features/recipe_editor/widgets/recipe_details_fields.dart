import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/tap/tap_extension.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';
import '../models/recipe_draft.dart';
import '../validation/recipe_editor_validation.dart';

import 'package:app_bep_xinh/core/widgets/app_text_field.dart';

import 'recipe_editor_section.dart';

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
  Widget build(
    BuildContext context,
  ) => BlocBuilder<RecipeEditorCubit, RecipeEditorState>(
    buildWhen: (previous, current) =>
        previous.draft.preparationMinutes != current.draft.preparationMinutes ||
        previous.draft.cookingMinutes != current.draft.cookingMinutes ||
        previous.draft.servings != current.draft.servings ||
        previous.draft.difficulty != current.draft.difficulty ||
        previous.isSubmitting != current.isSubmitting ||
        previous.errors['preparation'] != current.errors['preparation'] ||
        previous.errors['cooking'] != current.errors['cooking'],
    builder: (context, state) {
      final cubit = context.read<RecipeEditorCubit>();
      return RecipeEditorSection(
        title: 'Thông tin món',

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Khẩu phần (người)',
                    style: AppTextStyles.labelMedium,
                  ),
                ),
                _ServingButton(
                  label: 'Giảm khẩu phần',
                  icon: CupertinoIcons.minus,
                  onTap: state.isSubmitting || state.draft.servings <= 1
                      ? null
                      : () => cubit.changeServings(-1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '${state.draft.servings}',
                    style: AppTextStyles.labelMedium,
                  ),
                ),
                _ServingButton(
                  label: 'Tăng khẩu phần',
                  icon: CupertinoIcons.plus,
                  onTap:
                      state.isSubmitting ||
                          state.draft.servings >= RecipeEditorLimits.maxServings
                      ? null
                      : () => cubit.changeServings(1),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Độ khó', style: AppTextStyles.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final difficulty in RecipeDifficulty.values)
                  ChoiceChip(
                    label: Text(switch (difficulty) {
                      RecipeDifficulty.easy => 'Dễ',
                      RecipeDifficulty.medium => 'Vừa',
                      RecipeDifficulty.hard => 'Khó',
                    }),
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: state.draft.difficulty == difficulty
                          ? AppColors.primary800
                          : AppColors.textSecondary,
                    ),
                    selected: state.draft.difficulty == difficulty,
                    selectedColor: AppColors.primary50,
                    showCheckmark: false,
                    side: BorderSide(
                      color: state.draft.difficulty == difficulty
                          ? AppColors.primary100
                          : AppColors.border,
                    ),
                    backgroundColor: AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

class _ServingButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _ServingButton({required this.label, required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: AppTap(
      actionName: 'recipe_servings_$label',
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? AppColors.textMuted : AppColors.primary,
        ),
      ),
    ),
  );
}
