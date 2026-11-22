import 'package:flutter/material.dart';

class AppChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
  });
  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: false,
  );
}

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
  });
  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: false,
  );
}

class AppSelectionStyles {
  const AppSelectionStyles._();
  static ButtonStyle get segmented =>
      const ButtonStyle(side: WidgetStatePropertyAll(BorderSide.none));
}
