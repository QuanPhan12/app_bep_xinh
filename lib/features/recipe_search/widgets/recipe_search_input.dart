import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/widgets/app_search_bar.dart';

import '../cubits/recipe_search_cubit.dart';

/// Owns only the text controller; query, debounce and results live in Cubit.
class RecipeSearchInput extends StatefulWidget {
  const RecipeSearchInput({super.key});
  @override
  State<RecipeSearchInput> createState() => _RecipeSearchInputState();
}

class _RecipeSearchInputState extends State<RecipeSearchInput> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<RecipeSearchCubit>().state.request.query,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<RecipeSearchCubit, RecipeSearchState, bool>(
        selector: (state) => state.request.query.isNotEmpty,
        builder: (context, hasQuery) => AppSearchBar(
          controller: _controller,
          fieldKey: const ValueKey('recipe_search_query'),
          hintText: 'Tìm tên món hoặc nguyên liệu',
          onChanged: context.read<RecipeSearchCubit>().changeQuery,
          onSubmitted: () =>
              unawaited(context.read<RecipeSearchCubit>().load()),
          onClear: hasQuery
              ? () {
                  _controller.clear();
                  unawaited(context.read<RecipeSearchCubit>().clearQuery());
                }
              : null,
        ),
      );
}
