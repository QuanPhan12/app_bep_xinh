import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';
import 'package:app_bep_xinh/core/widgets/app_section_header.dart';
import 'package:app_bep_xinh/core/widgets/app_text_action.dart';

import '../cubits/fridge/fridge_cubit.dart';

class FridgeInventoryCard extends StatelessWidget {
  final VoidCallback onAddIngredients;
  const FridgeInventoryCard({super.key, required this.onAddIngredients});

  @override
  Widget build(BuildContext context) => BlocBuilder<FridgeCubit, FridgeState>(
    buildWhen: (a, b) =>
        a.selectedIds != b.selectedIds ||
        a.data != b.data ||
        a.isSaving != b.isSaving,
    builder: (context, state) => AppCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Nguyên liệu (${state.selectedIds.length})',
            action: AppTextAction(
              key: const ValueKey('fridge_add_ingredients'),
              label: 'Chỉnh sửa',
              padding: const EdgeInsets.symmetric(vertical: 14),
              actionName: 'fridge_open_ingredients',
              onTap: onAddIngredients,
            ),
          ),
          if (state.isSaving)
            Semantics(
              liveRegion: true,
              child: const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Đang lưu nguyên liệu…'),
              ),
            ),
          if (state.selectedIds.isEmpty)
            Text(
              'Thêm nguyên liệu bạn đang có.',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in state.selectedIngredients.take(6))
                  Container(
                    key: ValueKey('inventory_${item.id}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.name,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: context.colors.textSecondary),
                    ),
                  ),
                if (state.selectedIds.length > 6)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '+${state.selectedIds.length - 6}',
                      style: AppTextStyles.labelSmall,
                    ),
                  ),
              ],
            ),
        ],
      ),
    ),
  );
}
