import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';
import '../models/recipe_draft.dart';
import 'recipe_photo.dart';

class RecipeStepPhotoField extends StatelessWidget {
  final RecipeStepDraft step;
  final bool busy;
  const RecipeStepPhotoField({
    super.key,
    required this.step,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecipeEditorCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (step.photo case final photo?) ...[
          RecipePhoto(photo: photo),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [
              AppTextAction(
                label: 'Đổi ảnh',
                padding: const EdgeInsets.symmetric(vertical: 12),
                actionName: 'recipe_change_step_photo',
                onTap: busy ? null : () => cubit.pickStepPhoto(step.id),
              ),
              AppTextAction(
                label: 'Xóa ảnh',
                padding: const EdgeInsets.symmetric(vertical: 12),
                actionName: 'recipe_remove_step_photo',
                onTap: busy
                    ? null
                    : () => cubit.updateStep(step.id, removePhoto: true),
              ),
            ],
          ),
        ] else
          AppTextAction(
            key: ValueKey('recipe_step_photo_${step.id}'),
            actionName: 'recipe_step_photo',
            onTap: busy ? null : () => cubit.pickStepPhoto(step.id),
            label: 'Thêm ảnh minh họa bước này',
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
      ],
    );
  }
}
