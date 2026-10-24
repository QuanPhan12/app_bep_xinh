import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:flutter/material.dart';

/// UI tests kiểm tra layout/tương tác, không phụ thuộc tải Google Fonts.
void configureTestTextStyles() {
  AppTextStyles.titleLarge = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  AppTextStyles.headlineSmall = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  AppTextStyles.titleMedium = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  AppTextStyles.titleSmall = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  AppTextStyles.bodyMedium = const TextStyle(fontSize: 14);
  AppTextStyles.bodySmall = const TextStyle(fontSize: 12);
  AppTextStyles.labelLarge = const TextStyle(fontSize: 14);
  AppTextStyles.labelMedium = const TextStyle(fontSize: 12);
  AppTextStyles.labelSmall = const TextStyle(fontSize: 10);
  AppTextStyles.metaText = const TextStyle(fontSize: 12);
}
