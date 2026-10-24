import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../home/models/recipe_item.dart';
import 'product_card.dart';

/// Một cách tính tile dùng chung cho Home mobile/tablet, kể cả chữ lớn.
class ProductGrid extends StatelessWidget {
  final List<RecipeItem> recipes;
  final int columns;
  final double spacing;
  final double runSpacing;
  final double aspectRatio;
  final ValueChanged<RecipeItem> onRecipeTap;
  final FutureOr<void> Function(String) onFavoriteTap;

  const ProductGrid({
    super.key,
    required this.recipes,
    required this.columns,
    required this.spacing,
    required this.runSpacing,
    required this.aspectRatio,
    required this.onRecipeTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final width =
          (constraints.crossAxisExtent - spacing * (columns - 1)) / columns;
      final height = math.max(
        width / aspectRatio,
        ProductCard.minimumHeight(context, width),
      );
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          mainAxisExtent: height,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final recipe = recipes[index];
          return ProductCard(
            key: ValueKey(recipe.id),
            recipe: recipe,
            onTap: () => onRecipeTap(recipe),
            onFavoriteTap: () => onFavoriteTap(recipe.id),
          );
        }, childCount: recipes.length),
      );
    },
  );
}
