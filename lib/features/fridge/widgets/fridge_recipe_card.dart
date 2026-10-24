import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../models/fridge_recipe.dart';

class FridgeRecipeCard extends StatelessWidget {
  final FridgeRecipe recipe;
  final List<String> missingNames;
  final VoidCallback? onTap;
  const FridgeRecipeCard({
    super.key,
    required this.recipe,
    required this.missingNames,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppTap(
    actionName: 'fridge_recipe_${recipe.id}',
    onTap: onTap,
    child: AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recipe.image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                recipe.image!,
                width: 80,
                height: 88,
                fit: BoxFit.cover,
                cacheWidth: (80 * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.title, style: AppTextStyles.titleSmall),
                const SizedBox(height: 6),
                Text(
                  missingNames.isEmpty
                      ? recipe.description
                      : 'Cần thêm: ${missingNames.join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${recipe.minutes} phút${missingNames.isEmpty ? ' · Đủ nguyên liệu' : ''}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
