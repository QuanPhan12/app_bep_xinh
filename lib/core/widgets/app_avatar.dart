import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../text_styles/app_text_styles.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final String? assetPath;
  final String? imageUrl;
  final double size;
  final double? cornerRadius;
  final bool monochrome;
  const AppAvatar({
    super.key,
    required this.name,
    this.assetPath,
    this.imageUrl,
    this.size = 44,
    this.cornerRadius,
    this.monochrome = false,
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
      color: monochrome
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : context.colors.primary50,
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: AppTextStyles.labelLarge.copyWith(
            color: monochrome
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onPrimaryContainer,
            fontSize: (size * .32).clamp(12, 24).toDouble(),
          ),
        ),
      ),
    );
    final remote = Uri.tryParse(imageUrl ?? '');
    final content =
        remote != null && remote.scheme == 'https' && remote.host.isNotEmpty
        ? Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                .round()
                .clamp(1, 256),
            errorBuilder: (_, _, _) => fallback,
          )
        : assetPath == null
        ? fallback
        : Image.asset(
            assetPath!,
            fit: BoxFit.cover,
            cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                .round()
                .clamp(1, 256),
            errorBuilder: (_, _, _) => fallback,
          );
    return Semantics(
      image: true,
      label: 'Ảnh đại diện của $name',
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: cornerRadius == null
              ? ClipOval(child: content)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(cornerRadius!),
                  child: content,
                ),
        ),
      ),
    );
  }
}
