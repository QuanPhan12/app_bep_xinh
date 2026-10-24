import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/widgets/app_action_bar.dart';
import 'package:app_bep_xinh/core/widgets/app_button.dart';

import '../cubits/recipe_detail/recipe_detail_cubit.dart';

class RecipeDetailActions extends StatelessWidget {
  const RecipeDetailActions({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
        buildWhen: (a, b) => a.cookingStep != b.cookingStep || a.tab != b.tab,
        builder: (context, state) {
          final cubit = context.read<RecipeDetailCubit>();
          final active = state.cookingStep;
          final inSteps = state.tab == RecipeDetailTab.steps;
          return AppActionBar(
            child: Row(
              children: [
                if (active != null && inSteps && active > 0) ...[
                  Expanded(
                    child: AppButton(
                      text: 'Bước trước',
                      variant: AppButtonVariant.ghost,
                      onPressed: cubit.previousStep,
                      actionName: 'recipe_previous_step',
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: AppButton(
                    text: active == null
                        ? 'Bắt đầu nấu'
                        : !inSteps
                        ? 'Tiếp tục nấu'
                        : active == state.recipe!.steps.length - 1
                        ? 'Hoàn tất'
                        : 'Bước tiếp theo',
                    onPressed: active == null || !inSteps
                        ? cubit.startCooking
                        : cubit.nextStep,
                    actionName: 'recipe_cooking_action',
                  ),
                ),
              ],
            ),
          );
        },
      );
}
