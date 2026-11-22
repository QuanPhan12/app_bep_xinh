import 'dart:async';

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/material.dart';

import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';

class FridgeIngredientChip extends StatelessWidget {
  final Ingredient ingredient;
  final bool selected;
  final bool removable;
  final FutureOr<void> Function() onTap;

  const FridgeIngredientChip({
    super.key,
    required this.ingredient,
    required this.selected,
    required this.onTap,
    this.removable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${removable ? 'Xóa' : 'Chọn'} ${ingredient.name}',
      child: AppTap(
        actionName:
            'fridge_${removable ? 'remove' : 'toggle'}_${ingredient.id}',
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? context.colors.primary50 : context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? context.colors.primary100 : context.colors.surfaceVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  ingredient.name,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontSize: 13,
                    color: selected
                        ? AppColors.primary800
                        : context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
