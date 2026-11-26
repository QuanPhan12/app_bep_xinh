import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../models/recipe_remix.dart';
import 'recipe_section.dart';
import '../../../sollume/shared/app_menu_section.dart';

class RecipeRemixAttribution extends StatelessWidget {
  const RecipeRemixAttribution({
    super.key,
    required this.remix,
    required this.onOpen,
    this.showChanges = true,
  });
  final RecipeRemix remix;
  final VoidCallback onOpen;
  final bool showChanges;
  @override
  Widget build(BuildContext context) => RecipeSection(
    title: 'Biến tấu từ công thức',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        remix.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Của ${remix.authorName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(PhosphorIconsBold.caretRight, size: 18),
              ],
            ),
          ),
        ),
        if (showChanges && remix.changes.isNotEmpty) ...[
          const SizedBox(height: 24),
          const AppMenuSection(title: 'Điều chỉnh của tác giả', children: []),
          const SizedBox(height: 8),
          Text(remix.changes, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    ),
  );
}
