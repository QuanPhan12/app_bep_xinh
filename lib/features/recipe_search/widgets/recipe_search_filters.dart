import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/widgets/app_selection_controls.dart';
import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:app_bep_xinh/features/recipes/presentation/recipe_labels.dart';

import '../models/recipe_search_request.dart';
import '../cubits/recipe_search_cubit.dart';

extension RecipeSearchFilterLabel on RecipeSearchFilter {
  String get label => switch (this) {
    RecipeSearchFilter.all => 'Tất cả',
    RecipeSearchFilter.newest => 'Món mới',
    _ => category!.label,
  };
}

class RecipeSearchFilters extends StatelessWidget {
  const RecipeSearchFilters({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocSelector<RecipeSearchCubit, RecipeSearchState, RecipeSearchFilter>(
        selector: (state) => state.request.filter,
        builder: (context, selected) => Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final filter in RecipeSearchFilter.values)
              AppChoiceChip(
                key: ValueKey('search_filter_${filter.id}'),
                label: filter.label,
                selected: selected == filter,
                onSelected: (_) => unawaited(
                  context.read<RecipeSearchCubit>().selectFilter(filter),
                ),
              ),
            if (selected != RecipeSearchFilter.all)
              AppTextAction(
                label: 'Bỏ lọc',
                leadingIcon: PhosphorIconsRegular.x,
                onTap: () => context.read<RecipeSearchCubit>().selectFilter(
                  RecipeSearchFilter.all,
                ),
              ),
          ],
        ),
      );
}
