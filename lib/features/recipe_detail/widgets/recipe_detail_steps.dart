import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/features/recipes/widgets/recipe_step_content.dart';

import '../cubits/recipe_detail/recipe_detail_cubit.dart';

class RecipeDetailSteps extends StatelessWidget {
  const RecipeDetailSteps({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
        buildWhen: (a, b) =>
            a.recipe != b.recipe || a.cookingStep != b.cookingStep,
        builder: (context, state) {
          final steps = state.recipe!.steps;
          final active = state.cookingStep;
          final indexes = active == null
              ? List.generate(steps.length, (i) => i)
              : [active];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final index in indexes)
                Padding(
                  key: ValueKey('detail_step_${steps[index].id}'),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RecipeStepContent(
                    step: steps[index],
                    number: index + 1,
                    total: active == null ? null : steps.length,
                  ),
                ),
            ],
          );
        },
      );
}
