import 'dart:async';

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_avatar.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/material.dart';

import '../models/recipe_author.dart';

class RecipeAuthorInfo extends StatelessWidget {
  final RecipeAuthor author;
  final FutureOr<void> Function()? onTap;
  const RecipeAuthorInfo({super.key, required this.author, this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: onTap == null
        ? 'Tác giả ${author.name}'
        : 'Xem hồ sơ của ${author.name}',
    child: AppTap(
      key: const ValueKey('recipe_author_profile'),
      actionName: 'recipe_view_author',
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AppAvatar(name: author.name, assetPath: author.avatarAsset),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(author.name, style: AppTextStyles.titleSmall),
                  if (author.handle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      '@${author.handle}',
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (onTap != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Xem hồ sơ',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
