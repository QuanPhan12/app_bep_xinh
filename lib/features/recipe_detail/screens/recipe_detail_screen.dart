import 'package:app_bep_xinh/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';

import 'views/recipe_detail_mobile_view.dart';
import 'views/recipe_detail_tablet_view.dart';

class RecipeDetailScreen extends StatelessWidget {
  final String recipeId;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: RecipeDetailMobileView(recipeId: recipeId),
      tablet: RecipeDetailTabletView(recipeId: recipeId),
    );
  }
}
