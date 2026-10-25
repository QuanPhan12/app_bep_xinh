import 'package:flutter/material.dart';

import '../text_styles/app_text_styles.dart';
import 'app_feature_theme.dart';
import 'app_card.dart';

/// A quiet editorial opening with an optional food photo, no fixed text height.
class AppFeatureHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;
  final String? imageAsset;
  final bool green;
  const AppFeatureHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.imageAsset,
    this.green = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: green ? AppFeatureTheme.herbWash : AppFeatureTheme.peach,
      borderRadius: BorderRadius.circular(AppCard.radius),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: green
                        ? AppFeatureTheme.herb
                        : const Color(0xFF995128),
                    fontWeight: FontWeight.w700,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppFeatureTheme.ink,
                    letterSpacing: -.6,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppFeatureTheme.muted,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          if (imageAsset != null &&
              constraints.maxWidth >= 300 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3) ...[
            const SizedBox(width: 20),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imageAsset!,
                  width: constraints.maxWidth > 650 ? 132 : 88,
                  height: constraints.maxWidth > 650 ? 132 : 104,
                  fit: BoxFit.cover,
                  cacheWidth: 400,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
