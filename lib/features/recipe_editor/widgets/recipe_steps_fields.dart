import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';
import '../models/recipe_draft.dart';
import '../validation/recipe_editor_validation.dart';

import 'package:app_bep_xinh/core/widgets/app_text_field.dart';

import 'recipe_editor_section.dart';

class RecipeStepsFields extends StatelessWidget {
  const RecipeStepsFields({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocSelector<RecipeEditorCubit, RecipeEditorState, (int, bool, String?)>(
    selector: (state) =>
        (state.draft.steps.length, state.isSubmitting, state.errors['steps']),
    builder: (context, value) {
      final cubit = context.read<RecipeEditorCubit>();
      final items = cubit.state.draft.steps;
      return RecipeEditorSection(
        title: 'Cách thực hiện',

        action: AppTextAction(
          padding: const EdgeInsets.symmetric(vertical: 8),
          leadingIcon: Icons.add,
          label: 'Thêm bước',
          actionName: 'recipe_add_step',
          onTap: value.$2 || value.$1 >= RecipeEditorLimits.steps
              ? null
              : cubit.addStep,
        ),
        child: Column(
          children: [
            if (value.$3 case final error?)
              Text(
                error,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            for (var i = 0; i < items.length; i++)
              Padding(
                key: ValueKey(items[i].id),
                padding: EdgeInsets.only(
                  bottom: i == items.length - 1 ? 0 : 16,
                ),
                child: _StepFields(
                  id: items[i].id,
                  number: i + 1,
                  canRemove: items.length > 1,
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
  const _StepFields({
    required this.id,
    required this.number,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        RecipeEditorCubit,
        RecipeEditorState,
        (RecipeStepDraft?, String?, bool)
      >(
        selector: (state) => (
          state.draft.steps.where((item) => item.id == id).firstOrNull,
          state.errors[RecipeEditorValidation.stepInstruction(id)],
          state.isSubmitting,
        ),
        builder: (context, value) {
          final item = value.$1;
          if (item == null) return const SizedBox.shrink();
          final cubit = context.read<RecipeEditorCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bước $number',
                      style: AppTextStyles.labelMedium,
                    ),
                  ),
                  if (canRemove)
                    RecipeEditorRemoveAction(
                      label: 'Xóa bước $number',
                      onTap: value.$3 ? null : () => cubit.removeStep(id),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              AppTextField(
                fieldId: 'recipe_step_$id',
                initialValue: item.instruction,
                hint: 'Mô tả cách thực hiện',
                error: value.$2,
                enabled: !value.$3,
                minLines: 2,
                maxLines: 5,
                maxLength: RecipeEditorLimits.instructionLength,
                onChanged: (text) => cubit.changeStep(id, text),
              ),
            ],
          );
        },
      );
}
