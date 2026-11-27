import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_editor/recipe_editor_cubit.dart';
import 'recipe_editor_labels.dart';

class RecipeEditorProgress extends StatelessWidget {
  const RecipeEditorProgress({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecipeEditorCubit, RecipeEditorState>(
        buildWhen: (previous, current) =>
            previous.step != current.step ||
            previous.furthestStep != current.furthestStep ||
            previous.isBusy != current.isBusy,
        builder: (context, state) => Container(
          decoration: BoxDecoration(color: context.colors.background),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final step in RecipeEditorStep.values)
                    Expanded(
                      child: Semantics(
                        selected: state.step == step,
                        child: AppTap(
                          key: ValueKey('recipe_stage_${step.name}'),
                          actionName: 'recipe_stage_${step.name}',
                          onTap: state.isBusy || step.index > state.furthestStep
                              ? null
                              : () => context
                                    .read<RecipeEditorCubit>()
                                    .goToStep(step),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 4,
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    step.label,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: step == state.step
                                          ? AppColors.primary
                                          : context.colors.textSecondary,
                                      fontWeight: step == state.step
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: step.index < state.step.index
                                        ? AppColors.primary
                                        : step == state.step
                                        ? AppColors.primary
                                        : context.colors.border,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}
