import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:app_bep_xinh/core/widgets/app_text_field.dart';
import 'package:app_bep_xinh/core/widgets/app_serving_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';
import '../models/recipe_draft.dart';
import '../validation/recipe_editor_validation.dart';
import 'recipe_editor_section.dart';
import 'recipe_ingredient_sheet.dart';
import 'recipe_editor_menu.dart';

import 'package:app_bep_xinh/core/widgets/app_card.dart';

class RecipeIngredientsFields extends StatelessWidget {
  const RecipeIngredientsFields({super.key});

  Future<void> _edit(
    BuildContext context,
    String groupId, [
    RecipeIngredientDraft? item,
  ]) async {
    final cubit = context.read<RecipeEditorCubit>();
    final result = await showRecipeIngredientSheet(context, initial: item);
    if (result != null && !cubit.isClosed) {
      cubit.upsertIngredient(result, groupId: groupId);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<
        RecipeEditorCubit,
        RecipeEditorState,
        (
          List<RecipeIngredientDraft>,
          List<RecipeIngredientGroup>,
          Map<String, String>,
          bool,
        )
      >(
        selector: (state) => (
          state.draft.ingredients,
          state.draft.ingredientGroups,
          state.errors,
          state.isBusy,
        ),
        builder: (context, value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (value.$3['ingredients'] ?? value.$3['groups'] case final error?)
              Text(
                error,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.colors.error,
                ),
              ),
            for (final group in value.$2) ...[
              RecipeEditorSection(
                title: group.name,
                action: RecipeEditorMenu(
                  label: 'Tùy chọn ${group.name}',
                  enabled: !value.$4,
                  actions: [
                    (
                      label: 'Đổi tên nhóm',
                      onTap: () => _renameGroup(context, group),
                    ),
                    if (value.$2.length > 1)
                      (
                        label: 'Xóa nhóm',
                        onTap: () => context
                            .read<RecipeEditorCubit>()
                            .removeIngredientGroup(group.id),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (value.$3['group.${group.id}'] case final error?)
                      Text(
                        error,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.colors.error,
                        ),
                      ),
                    if (!value.$1.any((item) => item.groupId == group.id))
                      Text(
                        'Chưa có nguyên liệu trong nhóm này.',
                        style: AppTextStyles.bodySmall,
                      ),
                    for (final item in value.$1.where(
                      (item) => item.groupId == group.id,
                    ))
                      Padding(
                        key: ValueKey('recipe_ingredient_${item.id}'),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _IngredientRow(
                          item: item,
                          error:
                              value.$3[RecipeEditorValidation.ingredientError(
                                item.id,
                              )],
                          onEdit: value.$4
                              ? null
                              : () => _edit(context, group.id, item),
                          onRemove: value.$4
                              ? null
                              : () => context
                                    .read<RecipeEditorCubit>()
                                    .removeIngredient(item.id),
                        ),
                      ),
                    AppTextAction(
                      key: ValueKey('recipe_add_ingredient_${group.id}'),
                      label: 'Thêm nguyên liệu',
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      actionName: 'recipe_add_ingredient',
                      onTap:
                          value.$4 ||
                              value.$1.length >= RecipeEditorLimits.ingredients
                          ? null
                          : () => _edit(context, group.id),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            AppTextAction(
              label: 'Thêm nhóm nguyên liệu',
              padding: const EdgeInsets.symmetric(vertical: 16),
              actionName: 'recipe_add_group',
              onTap: value.$4 || value.$2.length >= RecipeEditorLimits.groups
                  ? null
                  : context.read<RecipeEditorCubit>().addIngredientGroup,
            ),
          ],
        ),
      );

  Future<void> _renameGroup(
    BuildContext context,
    RecipeIngredientGroup group,
  ) async {
    final cubit = context.read<RecipeEditorCubit>();
    var name = group.name;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đổi tên nhóm'),
        content: AppTextField(
          fieldId: 'recipe_group_name',
          initialValue: name,
          hint: 'Ví dụ: Nước chấm',
          maxLength: RecipeEditorLimits.groupNameLength,
          onChanged: (value) => name = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (name.trim().isNotEmpty) {
                Navigator.of(dialogContext).pop(name.trim());
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result != null && !cubit.isClosed) {
      cubit.renameIngredientGroup(group.id, result);
    }
  }
}

class RecipeIngredientSummary extends StatelessWidget {
  const RecipeIngredientSummary({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocSelector<RecipeEditorCubit, RecipeEditorState, (String, int, bool)>(
        selector: (state) =>
            (state.draft.title, state.draft.servings, state.isSubmitting),
        builder: (context, value) => AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value.$1, style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              AppServingSelector(
                value: value.$2,
                max: RecipeEditorLimits.maxServings,
                onChanged: value.$3
                    ? null
                    : (servings) => context
                          .read<RecipeEditorCubit>()
                          .changeServings(servings - value.$2),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhập lượng nguyên liệu cho khẩu phần trên. Thay đổi khẩu phần không tự quy đổi lượng đã nhập.',
                style: AppTextStyles.bodySmall,
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
      border: Border(bottom: BorderSide(color: context.colors.border)),
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
                      color: context.colors.textSecondary,
                    ),
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.colors.error,
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
