import 'package:flutter/material.dart';

import '../colors/app_colors.dart';

/// Scoped presentation for feature pages. Home, Cart and Auth keep the app theme.
class AppFeatureTheme extends StatelessWidget {
  final Widget child;
  const AppFeatureTheme({super.key, required this.child});

  static const canvas = Color(0xFFFBF8F4);
  static const line = Color(0xFFEDE5DB);
  static const ink = Color(0xFF302A24);
  static const muted = Color(0xFF766C61);
  static const herb = Color(0xFF35644B);
  static const herbWash = Color(0xFFEDF3EC);
  static const peach = Color(0xFFFFF0E2);

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FeatureMarker>() != null;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return _FeatureMarker(
      child: Theme(
        data: base.copyWith(
          scaffoldBackgroundColor: canvas,
          colorScheme: base.colorScheme.copyWith(
            primary: AppColors.primary,
            primaryContainer: AppColors.primary50,
            secondary: herb,
            secondaryContainer: herbWash,
            onSurface: ink,
            onSurfaceVariant: muted,
            outlineVariant: line,
          ),
          inputDecorationTheme: base.inputDecorationTheme.copyWith(
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary700,
                width: 1.5,
              ),
            ),
          ),
          listTileTheme: const ListTileThemeData(
            contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            iconColor: herb,
          ),
          bottomSheetTheme: base.bottomSheetTheme.copyWith(
            backgroundColor: canvas,
            surfaceTintColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
          dialogTheme: base.dialogTheme.copyWith(
            backgroundColor: canvas,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: AppColors.primary,
            linearTrackColor: AppColors.primary50,
            borderRadius: BorderRadius.all(Radius.circular(6)),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _FeatureMarker extends InheritedTheme {
  const _FeatureMarker({required super.child});
  @override
  bool updateShouldNotify(_FeatureMarker oldWidget) => false;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      _FeatureMarker(child: child);
}
