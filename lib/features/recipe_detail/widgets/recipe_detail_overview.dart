import 'package:flutter/material.dart';
import 'package:app_bep_xinh/features/recipes/widgets/recipe_content_overview.dart';
import 'package:app_bep_xinh/features/recipes/widgets/recipe_author_info.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:go_router/go_router.dart';

import '../models/recipe_detail.dart';

class RecipeDetailOverview extends StatelessWidget {
  final RecipeDetail recipe;
  const RecipeDetailOverview({super.key, required this.recipe});
  @override
  Widget build(BuildContext context) => RecipeContentOverview(
    content: recipe.content,
    authorInfo: RecipeAuthorInfo(
      author: recipe.author,
      onTap: recipe.author.id == null
          ? null
          : () {
              context.push(PathRouter.publicProfile(recipe.author.id!));
            },
    ),
    rating: recipe.rating,
    calories: recipe.calories,
  );
}
