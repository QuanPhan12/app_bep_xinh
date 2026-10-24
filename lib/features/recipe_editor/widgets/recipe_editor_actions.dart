import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';

class RecipeEditorActions extends StatelessWidget {
  const RecipeEditorActions({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        RecipeEditorCubit,
        RecipeEditorState,
        (RecipeEditorOperation, bool, bool)
      >(
        selector: (state) =>
            (state.operation, state.hasUnsavedChanges, state.errors.isNotEmpty),
        builder: (context, value) {
          final cubit = context.read<RecipeEditorCubit>();
          final busy = value.$1 != RecipeEditorOperation.idle;
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.maxContentWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (value.$3)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Kiểm tra các mục chưa hợp lệ trước khi gửi.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Lưu nháp',
                                actionName: 'recipe_save_draft',
                                variant: AppButtonVariant.ghost,
                                isLoading:
                                    value.$1 ==
                                    RecipeEditorOperation.savingDraft,
                                onPressed: busy || !value.$2
                                    ? null
                                    : cubit.saveDraft,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: AppButton(
                                text: 'Gửi duyệt',
                                actionName: 'recipe_submit',
                                isLoading:
                                    value.$1 ==
                                    RecipeEditorOperation.submitting,
                                onPressed: busy ? null : cubit.submit,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
