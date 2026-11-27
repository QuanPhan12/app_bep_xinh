import 'package:flutter/material.dart';

/// Bề mặt khám phá phẳng; icon/chip dùng màu chữ để ảnh món ăn giữ vai trò chính.
class RecipeDiscoveryTheme extends StatelessWidget {
  const RecipeDiscoveryTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Theme(
      data: theme.copyWith(
        iconTheme: theme.iconTheme.copyWith(color: colors.onSurface),
        iconButtonTheme: IconButtonThemeData(
          style: (theme.iconButtonTheme.style ?? const ButtonStyle()).copyWith(
            foregroundColor: WidgetStatePropertyAll(colors.onSurface),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: (theme.textButtonTheme.style ?? const ButtonStyle()).copyWith(
            foregroundColor: WidgetStatePropertyAll(colors.onSurface),
          ),
        ),
        chipTheme: theme.chipTheme.copyWith(
          side: BorderSide.none,
          backgroundColor: Colors.transparent,
          selectedColor: colors.surfaceContainerHighest,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            color: colors.onSurface,
          ),
          secondaryLabelStyle: theme.textTheme.labelLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottomSheetTheme: theme.bottomSheetTheme.copyWith(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: theme.dialogTheme.copyWith(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      child: child,
    );
  }
}
