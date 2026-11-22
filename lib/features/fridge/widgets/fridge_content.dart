import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:app_bep_xinh/core/widgets/app_sliver_content.dart';

import '../../../core/widgets/app_adaptive_columns.dart';

import 'dart:async';

import 'package:app_bep_xinh/core/widgets/app_sliver_app_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/fridge/fridge_cubit.dart';

import 'fridge_ingredient_sheet.dart';
import 'fridge_inventory_card.dart';
import 'fridge_recipe_suggestions.dart';

import 'package:go_router/go_router.dart';

import '../../kitchen/services/kitchen_services.dart';

/// Chỉ sắp xếp các thành phần; từng widget tự sở hữu card của mình.
class FridgeContent extends StatelessWidget {
  const FridgeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<FridgeCubit>().loadFridge,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        key: const PageStorageKey('fridge_content'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          AppSliverAppBar.tab(
            title: 'Tủ lạnh',
            actions: [
              if (KitchenScope.maybeOf(context)?.signedIn ?? false)
                IconButton(
                  // tooltip: 'Nguyên liệu & hạn dùng',
                  onPressed: () => context.push('/kitchen/pantry'),
                  icon: const Icon(Icons.inventory_2_outlined),
                ),
            ],
          ),
          AppSliverContent(
            maxWidth: AppLayout.pageWidth(context),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                sliver: SliverList.list(
                  children: [
                    AppAdaptiveColumns(
                      // Chữ lớn cần lại toàn bộ chiều rộng để danh sách nguyên liệu dễ đọc.
                      breakpoint:
                          MediaQuery.textScalerOf(context).scale(16) > 24
                          ? double.infinity
                          : 780,
                      secondaryFlex: 2,
                      primary: FridgeInventoryCard(
                        onAddIngredients: () {
                          unawaited(showFridgeIngredientSheet(context));
                        },
                      ),
                      secondary: const FridgeRecipeSuggestions(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
