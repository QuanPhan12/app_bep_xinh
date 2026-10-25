import 'package:app_bep_xinh/core/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/fridge/fridge_cubit.dart';

/// Text controller only; matching and inventory stay in FridgeCubit.
class FridgeIngredientSearch extends StatefulWidget {
  const FridgeIngredientSearch({super.key});
  @override
  State<FridgeIngredientSearch> createState() => _FridgeIngredientSearchState();
}

class _FridgeIngredientSearchState extends State<FridgeIngredientSearch> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<FridgeCubit>().state.query,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<FridgeCubit, FridgeState, bool>(
        selector: (state) => state.query.isNotEmpty,
        builder: (context, hasQuery) => AppSearchBar(
          controller: _controller,
          hintText: 'Tìm nguyên liệu: trứng, thịt bò…',
          fieldKey: const ValueKey('fridge_ingredient_search'),
          onChanged: context.read<FridgeCubit>().searchIngredients,
          onClear: hasQuery
              ? () {
                  _controller.clear();
                  context.read<FridgeCubit>().searchIngredients('');
                }
              : null,
        ),
      );
}
