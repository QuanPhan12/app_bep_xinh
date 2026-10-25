import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../text_styles/app_text_styles.dart';

const _shape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
);
const _padding = EdgeInsets.symmetric(horizontal: 10, vertical: 8);

TextStyle _label(bool selected, bool enabled) =>
    AppTextStyles.labelMedium.copyWith(
      color: !enabled
          ? AppColors.textMuted
          : selected
          ? AppColors.textWhite
          : AppColors.textSecondary,
      fontWeight: FontWeight.w600,
    );

/// Borderless single selection using the app's primary color.
class AppChoiceChip extends ChoiceChip {
  AppChoiceChip({
    super.key,
    required String label,
    required super.selected,
    super.onSelected,
  }) : super(
         label: Text(label),
         labelStyle: _label(selected, onSelected != null),
         selectedColor: AppColors.primary,
         backgroundColor: AppColors.surfaceVariant,
         disabledColor: AppColors.surfaceVariant,
         side: BorderSide.none,
         shape: _shape,
         padding: _padding,
         showCheckmark: false,
         materialTapTargetSize: MaterialTapTargetSize.padded,
       );
}

/// Same appearance as single selection, preserving multiple-selection semantics.
class AppFilterChip extends FilterChip {
  AppFilterChip({
    super.key,
    required String label,
    required super.selected,
    super.onSelected,
  }) : super(
         label: Text(label),
         labelStyle: _label(selected, onSelected != null),
         selectedColor: AppColors.primary,
         backgroundColor: AppColors.surfaceVariant,
         disabledColor: AppColors.surfaceVariant,
         side: BorderSide.none,
         shape: _shape,
         padding: _padding,
         showCheckmark: false,
         materialTapTargetSize: MaterialTapTargetSize.padded,
       );
}

class AppSelectionStyles {
  const AppSelectionStyles._();

  static ButtonStyle get segmented => ButtonStyle(
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    shape: const WidgetStatePropertyAll(_shape),
    side: const WidgetStatePropertyAll(BorderSide.none),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.primary
          : AppColors.surfaceVariant,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? AppColors.textMuted
          : states.contains(WidgetState.selected)
          ? AppColors.textWhite
          : AppColors.textSecondary,
    ),
  );
}
