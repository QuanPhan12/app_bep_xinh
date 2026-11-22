import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../recipes/widgets/recipe_image_view.dart';
import '../models/chat_recipe.dart';

class ChatRecipeCard extends StatelessWidget {
  const ChatRecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onRemove,
    this.sending = false,
  });
  final ChatRecipe recipe;
  final VoidCallback? onTap, onRemove;
  final bool sending;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RecipeImageView(image: recipe.cover, aspectRatio: 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Công thức',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            if (onRemove != null)
              IconButton(
                tooltip: 'Bỏ công thức đính kèm',
                onPressed: sending ? null : onRemove,
                icon: const Icon(PhosphorIconsRegular.x, size: 18),
              )
            else if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(PhosphorIconsBold.caretRight, size: 16),
            ],
          ],
        ),
      ),
    ),
  );
}
