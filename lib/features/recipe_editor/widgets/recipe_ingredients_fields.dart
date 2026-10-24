import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';
import '../models/recipe_draft.dart';
import '../validation/recipe_editor_validation.dart';
import 'recipe_editor_section.dart';
import 'recipe_ingredient_sheet.dart';

class RecipeIngredientsFields extends StatelessWidget {
  const RecipeIngredientsFields({super.key});

  Future<void> _edit(
    BuildContext context, [
    RecipeIngredientDraft? item,
  ]) async {
    final cubit = context.read<RecipeEditorCubit>();
    final result = await showRecipeIngredientSheet(context, initial: item);
    if (result != null && !cubit.isClosed) cubit.upsertIngredient(result);
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        RecipeEditorCubit,
        RecipeEditorState,
        (List<RecipeIngredientDraft>, Map<String, String>, bool)
      >(
        selector: (state) =>
            (state.draft.ingredients, state.errors, state.isSubmitting),
        builder: (context, value) => RecipeEditorSection(
          title: 'Nguyên liệu',

          action: AppTextAction(
            padding: const EdgeInsets.symmetric(vertical: 8),
            leadingIcon: Icons.add,
            label: 'Thêm',
            actionName: 'recipe_add_ingredient',
            onTap: value.$3 || value.$1.length >= RecipeEditorLimits.ingredients
                ? null
                : () => _edit(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (value.$2['ingredients'] case final error?)
                Text(
                  error,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              if (value.$1.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Chọn nguyên liệu và lượng dùng cho món ăn.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              for (final item in value.$1)
                Padding(
                  key: ValueKey('recipe_ingredient_${item.id}'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _IngredientRow(
                    item: item,
                    error: value
                        .$2[RecipeEditorValidation.ingredientError(item.id)],
                    onEdit: value.$3 ? null : () => _edit(context, item),
                    onRemove: value.$3
                        ? null
                        : () => context
                              .read<RecipeEditorCubit>()
                              .removeIngredient(item.id),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _IngredientRow extends StatelessWidget {
  final RecipeIngredientDraft item;
  final String? error;
  final Future<void> Function()? onEdit;
  final VoidCallback? onRemove;
  const _IngredientRow({
    required this.item,
    this.error,
    this.onEdit,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.zero,
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        Expanded(
          child: AppTap(
            actionName: 'recipe_edit_ingredient_${item.id}',
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    [
                      item.quantityLabel,
                      if (item.note.isNotEmpty) item.note,
                    ].join(' · '),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        RecipeEditorRemoveAction(label: 'Xóa ${item.name}', onTap: onRemove),
      ],
    ),
  );
}
