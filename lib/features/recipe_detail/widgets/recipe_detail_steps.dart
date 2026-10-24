import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_section_header.dart';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final index in indexes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(
                        title: active == null
                            ? 'Bước ${index + 1}'
                            : 'Bước ${index + 1} / ${steps.length}',
                        action: steps[index].minutes == null
                            ? null
                            : Text(
                                '${steps[index].minutes} phút',
                                style: AppTextStyles.bodySmall,
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        steps[index].instruction,
                        style: AppTextStyles.bodyMedium,
                      ),
                      if (active == null && index < steps.length - 1)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Divider(height: 1),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      );
}
