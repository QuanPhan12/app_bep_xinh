import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../constants/app_assets.dart';

/// Nội dung rỗng dùng chung; màn cha giữ quyền cuộn và xử lý hành động.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.title,
    required this.message,
    this.action,
    this.illustrationAsset = AppAssets.emptyState,
    this.fallbackIcon = PhosphorIconsRegular.forkKnife,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
  });

  final String? title;
  final String message;
  final Widget? action;
  final String illustrationAsset;
  final IconData fallbackIcon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                illustrationAsset,
                width: 176,
                height: 144,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => SizedBox(
                  width: 176,
                  height: 144,
                  child: Icon(
                    fallbackIcon,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (title != null) ...[
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        ),
      ),
    );
  }
}
