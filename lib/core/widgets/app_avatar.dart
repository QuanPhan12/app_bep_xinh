import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../text_styles/app_text_styles.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final String? assetPath;
  final double size;
  const AppAvatar({
    super.key,
    required this.name,
    this.assetPath,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first)
        .join()
        .toUpperCase();
    final fallback = ColoredBox(
      color: AppColors.primary50,
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primary,
            fontSize: (size * .32).clamp(12, 24),
          ),
        ),
      ),
    );
    return Semantics(
      image: true,
      label: 'Ảnh đại diện của $name',
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: ClipOval(
            child: assetPath == null
                ? fallback
                : Image.asset(
                    assetPath!,
                    fit: BoxFit.cover,
                    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                        .round()
                        .clamp(1, 256),
                    errorBuilder: (_, _, _) => fallback,
                  ),
          ),
        ),
      ),
    );
  }
}
