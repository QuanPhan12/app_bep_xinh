import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';
import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';
import '../models/recipe_draft.dart';
import '../validation/recipe_editor_validation.dart';

import 'package:app_bep_xinh/core/widgets/app_text_field.dart';

import 'recipe_editor_section.dart';
import 'recipe_step_photo_field.dart';
import 'recipe_editor_menu.dart';

class RecipeStepsFields extends StatelessWidget {
  const RecipeStepsFields({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        RecipeEditorCubit,
        RecipeEditorState,
        (List<RecipeStepDraft>, bool, String?)
      >(
        selector: (state) =>
            (state.draft.steps, state.isBusy, state.errors['steps']),
        builder: (context, value) {
          final cubit = context.read<RecipeEditorCubit>();
          final items = value.$1;
          return RecipeEditorSection(
            title: 'Cách thực hiện',
            framed: false,

            action: AppTextAction(
              padding: const EdgeInsets.symmetric(vertical: 8),
              label: 'Thêm bước',
              actionName: 'recipe_add_step',
              onTap: value.$2 || value.$1.length >= RecipeEditorLimits.steps
                  ? null
                  : cubit.addStep,
            ),
            child: Column(
              children: [
                if (value.$3 case final error?)
                  Text(
                    error,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        SizedBox(
                          key: ValueKey(items[i].id),
                          width:
                              constraints.maxWidth >= AppLayout.splitBreakpoint
                              ? (constraints.maxWidth - 16) / 2
                              : constraints.maxWidth,
                          child: _StepFields(
                            id: items[i].id,
                            number: i + 1,
                            canRemove: items.length > 1,
                            isLast: i == items.length - 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _StepFields extends StatelessWidget {
  final String id;
  final int number;
  final bool canRemove;
  final bool isLast;
  const _StepFields({
    required this.id,
    required this.number,
    required this.canRemove,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        RecipeEditorCubit,
        RecipeEditorState,
        (RecipeStepDraft?, Map<String, String>, bool)
      >(
        selector: (state) => (
          state.draft.steps.where((item) => item.id == id).firstOrNull,
          state.errors,
          state.isBusy,
        ),
        builder: (context, value) {
          final item = value.$1;
          if (item == null) return const SizedBox.shrink();
          final cubit = context.read<RecipeEditorCubit>();
          return AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Bước $number',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    RecipeEditorMenu(
                      label: 'Tùy chọn bước $number',
                      enabled: !value.$3,
                      actions: [
                        (
                          label: 'Chuyển bước $number lên',
                          onTap: number == 1
                              ? null
                              : () => cubit.moveStep(id, -1),
                        ),
                        (
                          label: 'Chuyển bước $number xuống',
                          onTap: isLast ? null : () => cubit.moveStep(id, 1),
                        ),
                        if (canRemove)
                          (
                            label: 'Xóa bước $number',
                            onTap: () => cubit.removeStep(id),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                  fieldId: 'recipe_step_title_$id',
                  initialValue: item.title,
                  label: 'Tên bước (tùy chọn)',
                  hint: 'Ví dụ: Sơ chế nguyên liệu',
                  error: value.$2['stepTitle.$id'],
                  enabled: !value.$3,
                  maxLength: RecipeEditorLimits.stepTitleLength,
                  onChanged: (text) => cubit.updateStep(id, title: text),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  fieldId: 'recipe_step_$id',
                  initialValue: item.instruction,
                  hint: 'Mô tả cách thực hiện',
                  label: 'Cách thực hiện',
                  error: value.$2[RecipeEditorValidation.stepInstruction(id)],
                  enabled: !value.$3,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: RecipeEditorLimits.instructionLength,
                  onChanged: (text) => cubit.changeStep(id, text),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  fieldId: 'recipe_step_minutes_$id',
                  initialValue: item.minutes,
                  label: 'Thời gian (phút, tùy chọn)',
                  hint: 'Ví dụ: 10',
                  numeric: true,
                  error: value.$2['stepMinutes.$id'],
                  enabled: !value.$3,
                  maxLength: 3,
                  onChanged: (text) => cubit.updateStep(id, minutes: text),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  fieldId: 'recipe_step_tip_$id',
                  initialValue: item.tip,
                  label: 'Mẹo nhỏ (tùy chọn)',
                  hint: 'Bí quyết để bước này ngon hơn…',
                  error: value.$2['stepTip.$id'],
                  enabled: !value.$3,
                  maxLength: RecipeEditorLimits.noteLength,
                  maxLines: 3,
                  onChanged: (text) => cubit.updateStep(id, tip: text),
                ),
                const SizedBox(height: 16),
                RecipeStepPhotoField(step: item, busy: value.$3),
              ],
            ),
          );
        },
      );
}
