import 'package:flutter/material.dart';

import '../../sollume/core/theme/app_theme.dart' as sollume;
import 'app_palette.dart';

/// Theme gốc Sollume; facade giữ API cho các màn Bếp Xinh đang dùng.
abstract final class AppTheme {
  static ThemeData get lightTheme => _bridge(sollume.AppTheme.light);
  static ThemeData get darkTheme => _bridge(sollume.AppTheme.dark);
  static ThemeData buildLightTheme({
    TextTheme? textTheme,
    String? fontFamily,
  }) => _bridge(
    sollume.AppTheme.light,
    textTheme: textTheme,
    fontFamily: fontFamily,
  );
  static ThemeData buildDarkTheme({TextTheme? textTheme, String? fontFamily}) =>
      _bridge(
        sollume.AppTheme.dark,
        textTheme: textTheme,
        fontFamily: fontFamily,
      );
  static ThemeData _bridge(
    ThemeData theme, {
    TextTheme? textTheme,
    String? fontFamily,
  }) {
    final text = textTheme?.apply(
      bodyColor: theme.colorScheme.onSurface,
      displayColor: theme.colorScheme.onSurface,
      fontFamily: fontFamily,
    );
    return theme.copyWith(
      textTheme: text ?? theme.textTheme,
      extensions: [...theme.extensions.values, AppPalette(theme.colorScheme)],
    );
  }

  static Widget builder(BuildContext context, Widget? child) =>
      sollume.AppTheme.builder(
        context,
        Builder(
          builder: (context) => Theme(
            data: _bridge(Theme.of(context)),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );
}
