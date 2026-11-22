import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app_bep_xinh/core/utils/app_layout.dart';

import '../../home/models/recipe_item.dart';
import 'product_card.dart';

/// Một cách tính tile dùng chung cho Home, Profile và gợi ý từ tủ lạnh.
class ProductGrid extends StatelessWidget {
  final List<RecipeItem> recipes;
  final int? columns;
  final double spacing;
  final double runSpacing;
  final ValueChanged<RecipeItem> onRecipeTap;
  final FutureOr<void> Function(String)? onFavoriteTap;
  final String? Function(RecipeItem)? supportingTextBuilder;
  final bool sliver;

  const ProductGrid({
    super.key,
    required this.recipes,
    this.columns,
    required this.spacing,
    required this.runSpacing,
    required this.onRecipeTap,
    this.onFavoriteTap,
    this.supportingTextBuilder,
    this.sliver = true,
  });

  @override
  Widget build(BuildContext context) => sliver
      ? SliverLayoutBuilder(
          builder: (context, constraints) =>
              _buildGrid(context, constraints.crossAxisExtent),
        )
      : LayoutBuilder(
          builder: (context, constraints) =>
              _buildGrid(context, constraints.maxWidth),
        );

  Widget _buildGrid(BuildContext context, double extent) {
    final count = columns ?? AppLayout.gridColumns(extent, spacing: spacing);
    final width = (extent - spacing * (count - 1)) / count;
    final height = recipes.fold<double>(
      0,
      (tallest, recipe) => math.max(
        tallest,
        ProductCard.contentHeight(
          context,
          width,
          recipe,
          supportingText: supportingTextBuilder?.call(recipe),
        ),
      ),
    );
    final grid = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: count,
      crossAxisSpacing: spacing,
      mainAxisSpacing: runSpacing,
      mainAxisExtent: height,
    );
    final children = SliverChildBuilderDelegate((context, index) {
      final recipe = recipes[index];
      return ProductCard(
        key: ValueKey(recipe.id),
        recipe: recipe,
        onTap: () => onRecipeTap(recipe),
        onFavoriteTap: onFavoriteTap == null
            ? null
            : () => onFavoriteTap!(recipe.id),
        supportingText: supportingTextBuilder?.call(recipe),
      );
    }, childCount: recipes.length);
    if (sliver) return SliverGrid(gridDelegate: grid, delegate: children);
    // Scroll do màn cha sở hữu; grid trong cột tủ lạnh không tạo cuộn riêng.
    return GridView.custom(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: grid,
      childrenDelegate: children,
    );
  }
}
