import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/search_utils.dart';

import '../../recipes/widgets/recipe_section.dart';
import '../cubits/recipe_search_cubit.dart';

class RecipeSearchHistory extends StatelessWidget {
  const RecipeSearchHistory({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RecipeSearchCubit, RecipeSearchState>(
        buildWhen: (a, b) =>
            a.recentQueries != b.recentQueries ||
            a.request.query != b.request.query,
        builder: (context, state) {
          final term = searchKey(state.request.query);
          final queries = state.recentQueries
              .where(
                (query) =>
                    term.isEmpty ||
                    (searchKey(query).contains(term) &&
                        searchKey(query) != term),
              )
              .take(term.isEmpty ? 8 : 3)
              .toList();
          if (queries.isEmpty) {
            return const SizedBox.shrink();
          }
          final cubit = context.read<RecipeSearchCubit>();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: RecipeSection(
              title: term.isEmpty ? 'Tìm kiếm gần đây' : 'Gợi ý tìm kiếm',
              action: term.isEmpty
                  ? TextButton(
                      onPressed: cubit.clearHistory,
                      child: const Text('Xóa lịch sử'),
                    )
                  : null,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final query in queries)
                    ActionChip(
                      label: Text(query),
                      side: BorderSide.none,
                      onPressed: () => cubit.selectRecent(query),
                    ),
                ],
              ),
            ),
          );
        },
      );
}
