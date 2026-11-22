import 'package:flutter/material.dart';
import 'package:app_bep_xinh/features/recipes/widgets/recipe_image_view.dart';

import '../models/recipe_draft.dart';

class RecipePhoto extends StatelessWidget {
  final RecipeImage photo;
  final double aspectRatio;
  const RecipePhoto({
    super.key,
    required this.photo,
    this.aspectRatio = 16 / 9,
  });
  @override
  Widget build(BuildContext context) =>
      RecipeImageView(image: photo, aspectRatio: aspectRatio);
}
