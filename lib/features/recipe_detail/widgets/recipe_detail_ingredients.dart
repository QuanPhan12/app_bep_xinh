import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_serving_selector.dart';
import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:app_bep_xinh/core/widgets/app_section_header.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';

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
              AppCard(
                padding: const EdgeInsets.all(16),
                child: AppServingSelector(
                  value: state.servings,
                  onChanged: cubit.changeServings,
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      for (final group in recipe.ingredientGroups)
                        if (recipe.ingredients.any(
                          (item) => item.groupId == group.id,
                        )) ...[
                          const SizedBox(height: 16),
                          Text(group.name, style: AppTextStyles.titleSmall),
                          const SizedBox(height: 4),
                          for (final item in recipe.ingredients.where(
                            (item) => item.groupId == group.id,
                          ))
                            CheckboxListTile(
                              key: ValueKey('detail_ingredient_${item.id}'),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: state.checkedIngredients.contains(item.id),
                              onChanged: (_) => cubit.toggleIngredient(item.id),
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.name,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    flex: 2,
                                    child: Text(
                                      item.quantityForServings(
                                        state.servings,
                                        recipe.servings,
                                      ),
                                      textAlign: TextAlign.end,
                                      style: AppTextStyles.labelMedium,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: item.note.isEmpty
                                  ? null
                                  : Text(
                                      item.note,
                                      style: AppTextStyles.bodySmall,
                                    ),
                            ),
                        ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
}
