import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:flutter/material.dart';

import '../models/recipe_image.dart';

class RecipeImageView extends StatelessWidget {
  final RecipeImage image;
  final double aspectRatio;
  const RecipeImageView({
    super.key,
    required this.image,
    this.aspectRatio = 16 / 9,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cacheWidth =
              (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .round()
                  .clamp(1, 1600);
          Widget error(BuildContext _, Object _, StackTrace? _) =>
              const ColoredBox(
                color: AppColors.surfaceVariant,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textTertiary,
                  ),
                ),
              );
          final bytes = image.bytes;
          if (bytes != null) {
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              semanticLabel: image.name,
              cacheWidth: cacheWidth,
              errorBuilder: error,
            );
          }
          return Image.asset(
            image.assetPath!,
            fit: BoxFit.cover,
            semanticLabel: image.name,
            cacheWidth: cacheWidth,
            errorBuilder: error,
          );
        },
      ),
    ),
  );
}
