import 'package:flutter/material.dart';

/// A button label laid out using the effective button typography.
///
/// The button centers the paragraph's line box. Keep text in that layout box
/// so font fallback, diacritics, wrapping and system text scaling use Flutter's
/// text metrics instead of a font- or label-specific paint translation.
class AppButtonLabel extends StatelessWidget {
  const AppButtonLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    textHeightBehavior: const TextHeightBehavior(
      leadingDistribution: TextLeadingDistribution.even,
    ),
  );
}
