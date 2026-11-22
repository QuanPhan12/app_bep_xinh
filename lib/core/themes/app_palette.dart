import 'package:flutter/material.dart';

/// Màu theo Theme của từng cây widget; hai cửa sổ/preview không dùng chung biến màu toàn cục.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final ColorScheme scheme;
  const AppPalette(this.scheme);
  bool get isDark => scheme.brightness == Brightness.dark;
  Color get background => scheme.surface;
  Color get surface => scheme.surface;
  Color get surfaceVariant => scheme.surfaceContainer;
  Color get border => scheme.outlineVariant;
  Color get borderLight => scheme.outlineVariant.withValues(alpha: .5);
  Color get borderDark => scheme.outline;
  Color get textPrimary => scheme.onSurface;
  Color get textSecondary => scheme.onSurfaceVariant;
  Color get textTertiary => scheme.onSurfaceVariant;
  Color get textMuted => scheme.onSurfaceVariant.withValues(alpha: .7);
  Color get primary50 => scheme.primaryContainer;
  Color get primary100 => scheme.primaryContainer;
  Color get primary200 => scheme.primaryContainer;
  Color get action => scheme.primary;
  Color get secondary => scheme.onSecondaryContainer;
  Color get secondaryLight => scheme.secondaryContainer;
  Color get secondaryDark => secondary;
  Color get accentLight => scheme.tertiaryContainer;
  Color get success =>
      isDark ? const Color(0xFF8DD69A) : const Color(0xFF2B8A3E);
  Color get successBg => secondaryLight;
  Color get warning =>
      isDark ? const Color(0xFFFFCF73) : const Color(0xFF805500);
  Color get warningBg => accentLight;
  Color get error => scheme.error;
  Color get errorBg => scheme.errorContainer;
  Color get info => isDark ? const Color(0xFF9BCBFF) : const Color(0xFF1971C2);
  Color get infoBg =>
      isDark ? const Color(0xFF142539) : const Color(0xFFE7F5FF);
  @override
  AppPalette copyWith({ColorScheme? scheme}) =>
      AppPalette(scheme ?? this.scheme);
  @override
  AppPalette lerp(AppPalette? other, double t) => other == null
      ? this
      : AppPalette(ColorScheme.lerp(scheme, other.scheme, t));
}
