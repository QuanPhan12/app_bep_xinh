import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:flutter/material.dart';

import '../text_styles/app_text_styles.dart';

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
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                    letterSpacing: -.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
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
