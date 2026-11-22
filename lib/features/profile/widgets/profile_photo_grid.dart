import 'package:flutter/material.dart';

import '../../../core/colors/app_colors.dart';
import '../../home/models/recipe_item.dart';
import '../../home/widgets/home_feed_view.dart';

class ProfilePhotoGrid extends StatelessWidget {
  final List<RecipeItem> recipes;
  final ValueChanged<RecipeItem> onOpen;
  const ProfilePhotoGrid({
    super.key,
    required this.recipes,
    required this.onOpen,
  });
  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) => SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: constraints.crossAxisExtent >= 900
              ? 5
              : constraints.crossAxisExtent >= 650
              ? 4
              : 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 3 / 4,
        ),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Semantics(
            button: true,
            label: 'Mở công thức ${recipe.title}',
            child: Tooltip(
              message: recipe.title,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  key: ValueKey('profile_photo_${recipe.id}'),
                  onTap: () => onOpen(recipe),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FeedRecipeImage(
                        source: recipe.image,
                        label: recipe.title,
                      ),
                      if (recipe.isFavorite)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Icon(
                            Icons.bookmark,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: context.colors.textPrimary,
                                blurRadius: 4,
                              ),
                            ],
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
