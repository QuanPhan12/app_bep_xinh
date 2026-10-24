import 'package:flutter/material.dart';
import 'recipe_detail_mobile_view.dart';

class RecipeDetailTabletView extends StatelessWidget {
  final String recipeId;

  const RecipeDetailTabletView({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return RecipeDetailMobileView(recipeId: recipeId);
  }
}
