import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/widgets/app_selection_controls.dart';
import 'package:app_bep_xinh/core/widgets/app_text_action.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:app_bep_xinh/features/recipes/presentation/recipe_labels.dart';

import '../models/recipe_search_request.dart';
import '../cubits/recipe_search_cubit.dart';
import 'recipe_search_filter_sheet.dart';

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
      BlocSelector<RecipeSearchCubit, RecipeSearchState, RecipeSearchRequest>(
        selector: (state) => state.request,
        builder: (context, request) => Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final filter in RecipeSearchFilter.values)
              AppChoiceChip(
                key: ValueKey('search_filter_${filter.id}'),
                label: filter.label,
                selected: request.filter == filter,
                onSelected: (_) => unawaited(
                  context.read<RecipeSearchCubit>().selectFilter(filter),
                ),
              ),
            TextButton.icon(
              key: const ValueKey('search_open_filters'),
              icon: const Icon(
                PhosphorIconsRegular.slidersHorizontal,
                size: 18,
              ),
              label: Text(
                request.advancedCount == 0
                    ? 'Bộ lọc'
                    : 'Bộ lọc (${request.advancedCount})',
              ),
              onPressed: () async {
                final cubit = context.read<RecipeSearchCubit>();
                final result = await showRecipeSearchFilters(context, request);
                if (result != null && !cubit.isClosed) {
                  await cubit.applyFilters(result);
                }
              },
            ),
            if (request.maxMinutes != null)
              InputChip(
                label: Text('≤ ${request.maxMinutes} phút'),
                onDeleted: () => context.read<RecipeSearchCubit>().applyFilters(
                  request.copyWith(clearMinutes: true),
                ),
                deleteIcon: const Icon(PhosphorIconsRegular.x, size: 16),
                side: BorderSide.none,
              ),
            if (request.difficulty != null)
              InputChip(
                label: Text(request.difficulty!.label),
                onDeleted: () => context.read<RecipeSearchCubit>().applyFilters(
                  request.copyWith(clearDifficulty: true),
                ),
                deleteIcon: const Icon(PhosphorIconsRegular.x, size: 16),
                side: BorderSide.none,
              ),
            if (request.excludedIngredients.trim().isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 32,
                ),
                child: InputChip(
                  label: Text(
                    'Tránh: ${request.excludedIngredients}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  onDeleted: () => context
                      .read<RecipeSearchCubit>()
                      .applyFilters(request.copyWith(excludedIngredients: '')),
                  deleteIcon: const Icon(PhosphorIconsRegular.x, size: 16),
                  side: BorderSide.none,
                ),
              ),
            if (request.filter != RecipeSearchFilter.all ||
                request.advancedCount > 0)
              AppTextAction(
                label: 'Bỏ lọc',
                leadingIcon: PhosphorIconsRegular.x,
                onTap: context.read<RecipeSearchCubit>().clearFilters,
              ),
          ],
        ),
      );
}
