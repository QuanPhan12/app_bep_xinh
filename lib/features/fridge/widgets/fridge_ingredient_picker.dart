import 'package:app_bep_xinh/core/widgets/app_search_bar.dart';
import 'package:app_bep_xinh/core/widgets/app_section_header.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/fridge/fridge_cubit.dart';
import 'fridge_ingredient_chip.dart';

class FridgeIngredientPicker extends StatelessWidget {
  const FridgeIngredientPicker({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppSearchBar(
        hintText: 'Tìm nguyên liệu: trứng, thịt bò…',
        fieldKey: const ValueKey('fridge_ingredient_search'),
        onChanged: context.read<FridgeCubit>().searchIngredients,
      ),
      const SizedBox(height: 20),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Thêm nguyên liệu'),
          const SizedBox(height: 20),
          BlocBuilder<FridgeCubit, FridgeState>(
            buildWhen: (previous, current) =>
                previous.query != current.query ||
                previous.data != current.data ||
                previous.selectedIds != current.selectedIds,
            builder: (context, state) {
              final ingredients = state.visibleIngredients;
              if (ingredients.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Chưa có nguyên liệu phù hợp. Thử tìm tên khác nhé.',
                    style: AppTextStyles.bodyMedium,
                  ),
                );
              }
              final groups = ingredients.map((item) => item.group).toSet();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final group in groups)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            children: [
                              for (final item in ingredients.where(
                                (item) => item.group == group,
                              ))
                                FridgeIngredientChip(
                                  key: ValueKey('pick_${item.id}'),
                                  ingredient: item,
                                  selected: state.selectedIds.contains(item.id),
                                  onTap: () => context
                                      .read<FridgeCubit>()
                                      .toggleIngredient(item.id),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ],
  );
}
