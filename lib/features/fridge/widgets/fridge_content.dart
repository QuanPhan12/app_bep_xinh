import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/fridge/fridge_cubit.dart';

import 'fridge_ingredient_picker.dart';
import 'fridge_intro.dart';
import 'fridge_inventory_card.dart';
import 'fridge_recipe_suggestions.dart';

/// Chỉ sắp xếp các thành phần; từng widget tự sở hữu card của mình.
class FridgeContent extends StatelessWidget {
  const FridgeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<FridgeCubit>().loadFridge,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        key: const PageStorageKey('fridge_content'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(
          horizontal: 16.w(context),
          vertical: 16.h(context),
        ),
        children: [
          const FridgeIntro(),
          SizedBox(height: 20.h(context)),
          const FridgeInventoryCard(),
          SizedBox(height: 20.h(context)),
          const FridgeIngredientPicker(),
          SizedBox(height: 24.h(context)),
          const FridgeRecipeSuggestions(),
          SizedBox(height: 16.h(context)),
        ],
      ),
    );
  }
}
