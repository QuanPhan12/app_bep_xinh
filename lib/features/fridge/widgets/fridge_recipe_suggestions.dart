import 'package:app_bep_xinh/core/widgets/app_section_header.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/tap/tap_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/fridge/fridge_cubit.dart';
import 'fridge_recipe_card.dart';

class FridgeRecipeSuggestions extends StatelessWidget {
  const FridgeRecipeSuggestions({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FridgeCubit, FridgeState>(
      buildWhen: (previous, current) =>
          previous.selectedIds != current.selectedIds ||
          previous.data != current.data ||
          previous.filter != current.filter,
      builder: (context, state) {
        final ready = state.readyRecipes;
        final almostReady = state.almostReadyRecipes;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(title: 'Gợi ý cho bữa ăn'),
            SizedBox(height: 12.h(context)),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final filter in FridgeRecipeFilter.values)
                  ChoiceChip(
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: state.filter == filter
                          ? AppColors.primary100
                          : AppColors.border,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(switch (filter) {
                      FridgeRecipeFilter.all => 'Tất cả',
                      FridgeRecipeFilter.quick => '≤ 15 phút',
                      FridgeRecipeFilter.vegetarian => 'Món chay',
                    }),
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: state.filter == filter
                          ? AppColors.primary800
                          : AppColors.textSecondary,
                    ),
                    selectedColor: AppColors.primary50,
                    backgroundColor: AppColors.surface,
                    selected: state.filter == filter,
                    onSelected: (_) => context
                        .onAppTap(
                          () =>
                              context.read<FridgeCubit>().selectFilter(filter),
                          actionName: 'fridge_filter_${filter.name}',
                        )
                        ?.call(),
                  ),
              ],
            ),
            SizedBox(height: 16.h(context)),
            if (ready.isEmpty && almostReady.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w(context)),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.r(context)),
                ),
                child: Text(
                  state.selectedIds.isEmpty
                      ? 'Thêm nguyên liệu để xem món có thể nấu nhé.'
                      : 'Chưa có món phù hợp. Thử thêm nguyên liệu hoặc đổi bộ lọc nhé.',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            if (ready.isNotEmpty) ...[
              Text(
                'Nấu được ngay · ${ready.length} món',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 10.h(context)),
              for (final recipe in ready)
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h(context)),
                  child: FridgeRecipeCard(
                    recipe: recipe,
                    missingNames: const [],
                  ),
                ),
            ],
            if (almostReady.isNotEmpty) ...[
              SizedBox(height: 10.h(context)),
              Text(
                'Thiếu 1 nguyên liệu · ${almostReady.length} món',
                style: AppTextStyles.titleSmall,
              ),
              SizedBox(height: 10.h(context)),
              for (final recipe in almostReady)
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h(context)),
                  child: FridgeRecipeCard(
                    recipe: recipe,
                    missingNames: recipe
                        .missingIngredients(state.selectedIds)
                        .map(state.ingredientName)
                        .toList(),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
