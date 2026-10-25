import 'package:app_bep_xinh/core/widgets/app_card.dart';
import 'package:app_bep_xinh/core/widgets/app_section_header.dart';
import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/fridge/fridge_cubit.dart';
import 'fridge_ingredient_chip.dart';

import 'package:app_bep_xinh/core/widgets/app_button.dart';

/// Card nguyên liệu tự sở hữu nền, viền và khoảng cách bên trong.
class FridgeInventoryCard extends StatelessWidget {
  final VoidCallback onAddIngredients;
  const FridgeInventoryCard({super.key, required this.onAddIngredients});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FridgeCubit, FridgeState>(
      buildWhen: (previous, current) =>
          previous.selectedIds != current.selectedIds ||
          previous.data != current.data,
      builder: (context, state) {
        return AppCard(
          padding: EdgeInsets.all(16.w(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: 'Trong tủ lạnh (${state.selectedIds.length})',
                action: state.selectedIds.isEmpty
                    ? null
                    : AppTextAction(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        label: 'Xóa hết',
                        actionName: 'fridge_clear_all',
                        onTap: context.read<FridgeCubit>().clearIngredients,
                      ),
              ),
              SizedBox(height: 8.h(context)),
              if (state.selectedIds.isEmpty)
                Text(
                  'Thêm những nguyên liệu bạn đang có để tìm món phù hợp.',
                  style: AppTextStyles.bodyMedium,
                )
              else
                Wrap(
                  spacing: 6.w(context),
                  runSpacing: 6.h(context),
                  children: [
                    for (final item in state.selectedIngredients.take(6))
                      FridgeIngredientChip(
                        key: ValueKey('remove_${item.id}'),
                        ingredient: item,
                        selected: true,
                        removable: true,
                        onTap: () => context
                            .read<FridgeCubit>()
                            .removeIngredient(item.id),
                      ),
                    if (state.selectedIds.length > 6)
                      AppTextAction(
                        label: '+ ${state.selectedIds.length - 6} nguyên liệu',
                        onTap: onAddIngredients,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              AppButton(
                key: const ValueKey('fridge_add_ingredients'),
                text: 'Thêm nguyên liệu',
                variant: AppButtonVariant.secondary,
                actionName: 'fridge_open_ingredients',
                onPressed: onAddIngredients,
              ),
            ],
          ),
        );
      },
    );
  }
}
