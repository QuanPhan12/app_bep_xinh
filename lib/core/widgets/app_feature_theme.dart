import 'package:flutter/material.dart';

import '../colors/app_colors.dart';

/// Marker tương thích cho màn cũ; palette và component dùng chung AppTheme.
class AppFeatureTheme extends StatelessWidget {
  final Widget child;
  const AppFeatureTheme({super.key, required this.child});

  static const canvas = AppColors.background;
  static const line = AppColors.border;
  static const ink = AppColors.textPrimary;
  static const muted = AppColors.textTertiary;
  static const herb = AppColors.secondary;
  static const herbWash = AppColors.secondaryLight;
  static const peach = AppColors.primary50;

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FeatureMarker>() != null;

  // Marker giữ tương thích các màn cũ; style được lấy duy nhất từ AppTheme.
  @override
  Widget build(BuildContext context) => _FeatureMarker(child: child);
}

class _FeatureMarker extends InheritedTheme {
  const _FeatureMarker({required super.child});
  @override
  bool updateShouldNotify(_FeatureMarker oldWidget) => false;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      _FeatureMarker(child: child);
}
