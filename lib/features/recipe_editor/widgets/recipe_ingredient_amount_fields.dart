import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/ingredient_picker/ingredient_picker_cubit.dart';
import '../validation/recipe_editor_validation.dart';

import 'package:app_bep_xinh/core/widgets/app_text_field.dart';

class RecipeIngredientAmountFields extends StatelessWidget {
  const RecipeIngredientAmountFields({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<IngredientPickerCubit, IngredientPickerState>(
        builder: (context, state) {
          final cubit = context.read<IngredientPickerCubit>();
          return ListView(
            key: const ValueKey('ingredient_details'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(state.name, style: AppTextStyles.titleMedium),
                  ),
                  AppTextAction(
                    label: 'Đổi',
                    onTap: cubit.changeSelection,
                    actionName: 'ingredient_change',
                    allowConcurrent: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ],
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('Vừa đủ', style: AppTextStyles.bodyMedium),
                value: state.toTaste,
                onChanged: cubit.setToTaste,
              ),
              if (!state.toTaste) ...[
                AppTextField(
                  fieldId: 'ingredient_amount',
                  initialValue: state.amount,
                  label: 'Lượng dùng',
                  hint: 'Ví dụ: 200 hoặc 0,5',
                  decimal: true,
                  maxLength: 12,
                  error: state.errors['amount'],
                  onChanged: cubit.changeAmount,
                ),
                const SizedBox(height: 16),
                Text('Đơn vị', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<IngredientUnit>(
                  key: ValueKey('ingredient_unit_${state.unit?.id}'),
                  initialValue: state.unit,
                  isExpanded: true,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(errorText: state.errors['unit']),
                  items: [
                    for (final unit in state.availableUnits)
                      DropdownMenuItem(value: unit, child: Text(unit.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) cubit.selectUnit(value);
                  },
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                fieldId: 'ingredient_note',
                initialValue: state.note,
                label: 'Ghi chú (không bắt buộc)',
                hint: 'Ví dụ: thái mỏng, băm nhỏ',
                maxLength: RecipeEditorLimits.ingredientNoteLength,
                error: state.errors['note'],
                onChanged: cubit.changeNote,
              ),
            ],
          );
        },
      );
}
