import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/widgets/app_action_bar.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_button.dart';
import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';

class RecipeEditorActions extends StatelessWidget {
  const RecipeEditorActions({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<RecipeEditorCubit, RecipeEditorState>(
    buildWhen: (previous, current) =>
        previous.step != current.step ||
        previous.operation != current.operation ||
        previous.hasUnsavedChanges != current.hasUnsavedChanges ||
        previous.errors.isNotEmpty != current.errors.isNotEmpty,
    builder: (context, state) {
      final cubit = context.read<RecipeEditorCubit>();
      final busy = state.isBusy;
      return AppActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.errors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Kiểm tra các mục chưa hợp lệ để tiếp tục.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            if (state.step != RecipeEditorStep.details)
              Align(
                alignment: Alignment.centerLeft,
                child: AppTextAction(
                  label: 'Bước trước',
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  actionName: 'recipe_previous_step',
                  onTap: busy
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          cubit.previousStep();
                        },
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Lưu nháp',
                    actionName: 'recipe_save_draft',
                    variant: AppButtonVariant.secondary,
                    isLoading:
                        state.operation == RecipeEditorOperation.savingDraft,
                    onPressed: busy || !state.hasUnsavedChanges
                        ? null
                        : cubit.saveDraft,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    key: const ValueKey('recipe_continue'),
                    text: switch (state.step) {
                      RecipeEditorStep.details => 'Thêm nguyên liệu',
                      RecipeEditorStep.ingredients => 'Tiếp: Cách nấu',
                      RecipeEditorStep.instructions => 'Xem trước công thức',
                      RecipeEditorStep.review => 'Gửi duyệt công thức',
                    },
                    actionName: state.step == RecipeEditorStep.review
                        ? 'recipe_submit'
                        : 'recipe_next_step',
                    isLoading: state.isSubmitting,
                    onPressed: busy
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            if (state.step == RecipeEditorStep.review) {
                              return cubit.submit();
                            }
                            cubit.nextStep();
                            return Future<void>.value();
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
