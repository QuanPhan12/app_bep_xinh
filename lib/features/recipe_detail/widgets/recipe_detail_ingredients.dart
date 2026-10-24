import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_serving_selector.dart';
import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:app_bep_xinh/core/widgets/app_section_header.dart';

import '../cubits/recipe_detail/recipe_detail_cubit.dart';

class RecipeDetailIngredients extends StatelessWidget {
  const RecipeDetailIngredients({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
        buildWhen: (a, b) =>
            a.recipe != b.recipe ||
            a.servings != b.servings ||
            a.checkedIngredients != b.checkedIngredients,
        builder: (context, state) {
          final recipe = state.recipe!;
          final cubit = context.read<RecipeDetailCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppServingSelector(
                value: state.servings,
                onChanged: cubit.changeServings,
              ),
              const SizedBox(height: 20),
              AppSectionHeader(
                title: 'Nguyên liệu',
                action: AppTextAction(
                  label:
                      state.checkedIngredients.length ==
                          recipe.ingredients.length
                      ? 'Bỏ chọn'
                      : 'Chọn tất cả',
                  actionName: 'recipe_check_all',
                  onTap: cubit.toggleAllIngredients,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              Text(
                'Đánh dấu nguyên liệu bạn đã có.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final item in recipe.ingredients)
                CheckboxListTile(
                  key: ValueKey('detail_ingredient_${item.id}'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: state.checkedIngredients.contains(item.id),
                  onChanged: (_) => cubit.toggleIngredient(item.id),
                  title: Text(item.name, style: AppTextStyles.bodyMedium),
                  subtitle: item.note.isEmpty
                      ? null
                      : Text(item.note, style: AppTextStyles.bodySmall),
                  secondary: Text(
                    item.quantity(state.quantityRatio),
                    style: AppTextStyles.labelMedium,
                  ),
                ),
            ],
          );
        },
      );
}
