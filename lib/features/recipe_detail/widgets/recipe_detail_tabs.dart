import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_tabs.dart';
import '../cubits/recipe_detail/recipe_detail_cubit.dart';

class RecipeDetailTabs extends StatelessWidget {
  const RecipeDetailTabs({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
        buildWhen: (a, b) => a.recipe != b.recipe || a.tab != b.tab,
        builder: (context, state) => AppTabs(
          labels: [
            'Nguyên liệu (${state.recipe!.ingredients.length})',
            'Cách nấu (${state.recipe!.steps.length})',
          ],
          selectedIndex: state.tab.index,
          onSelected: (index) => context.read<RecipeDetailCubit>().selectTab(
            RecipeDetailTab.values[index],
          ),
        ),
      );
}
