import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:app_bep_xinh/features/recipes/widgets/recipe_content_overview.dart';
import 'package:app_bep_xinh/features/recipes/widgets/recipe_step_content.dart';
import 'package:app_bep_xinh/core/widgets/app_adaptive_columns.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';
import '../models/recipe_draft.dart';
import 'recipe_editor_section.dart';
import 'recipe_editor_tip.dart';

class RecipeReview extends StatelessWidget {
  const RecipeReview({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocSelector<RecipeEditorCubit, RecipeEditorState, RecipeDraft>(
    selector: (state) => state.draft,
    builder: (context, draft) => AppAdaptiveColumns(
      primary: RecipeEditorSection(
        title: 'Thông tin món ăn',
        action: const _ReviewEditAction(step: RecipeEditorStep.details),
        child: RecipeContentOverview(
          content: draft.toRecipeContent(),
          framed: false,
        ),
      ),
      secondary: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecipeEditorSection(
            title: 'Nguyên liệu (${draft.ingredients.length})',
            action: const _ReviewEditAction(step: RecipeEditorStep.ingredients),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final group in draft.ingredientGroups)
                  if (draft.ingredients.any(
                    (item) => item.groupId == group.id,
                  )) ...[
                    Text(group.name, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    for (final item in draft.ingredients.where(
                      (item) => item.groupId == group.id,
                    ))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  if (item.note.isNotEmpty)
                                    Text(
                                      item.note,
                                      style: AppTextStyles.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              flex: 2,
                              child: Text(
                                item.quantityLabel,
                                textAlign: TextAlign.end,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          RecipeEditorSection(
            title: '${draft.steps.length} bước nấu',
            action: const _ReviewEditAction(
              step: RecipeEditorStep.instructions,
            ),
            child: Column(
              children: [
                for (var index = 0; index < draft.steps.length; index++)
                  _ReviewStep(step: draft.steps[index], number: index + 1),
              ],
            ),
          ),
          if (draft.storageNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            RecipeEditorSection(
              title: 'Lưu ý & bí quyết bảo quản',
              child: Text(
                draft.storageNotes.trim(),
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: 24),
          const RecipeEditorTip(
            title: 'Gửi công thức đến Bếp Xinh',
            message: 'Công thức gửi đi sẽ ở trạng thái chờ duyệt. Hãy kiểm tra ảnh, định lượng và cách nấu trước khi gửi.',
          ),
        ],
      ),
    ),
  );
}

class _ReviewEditAction extends StatelessWidget {
  final RecipeEditorStep step;
  const _ReviewEditAction({required this.step});
  @override
  Widget build(BuildContext context) =>
      BlocSelector<RecipeEditorCubit, RecipeEditorState, bool>(
        selector: (state) => state.isBusy,
        builder: (context, busy) => AppTextAction(
          key: ValueKey('recipe_review_edit_${step.name}'),
          label: 'Chỉnh sửa',
          padding: const EdgeInsets.symmetric(vertical: 12),
          actionName: 'recipe_review_edit_${step.name}',
          onTap: busy
              ? null
              : () => context.read<RecipeEditorCubit>().goToStep(step),
        ),
      );
}

class _ReviewStep extends StatelessWidget {
  final RecipeStepDraft step;
  final int number;
  const _ReviewStep({required this.step, required this.number});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: RecipeStepContent(step: step.toRecipeStep(), number: number),
  );
}
