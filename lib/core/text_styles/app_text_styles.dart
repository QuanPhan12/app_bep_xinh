import '../colors/app_colors.dart';
import '../../sollume/core/theme/app_theme.dart' as sollume;

import 'package:flutter/material.dart';

/* Hệ thống Typography cho ứng dụng Bếp Xinh (Font Be Vietnam Pro) */
class AppTextStyles {
  const AppTextStyles._();

  /* Tên font chữ */
  static const String fontFamily = sollume.AppTextStyles.fontFamily;

  // Style tương thích kế thừa màu chữ từ Theme để không cố định màu light.
  static final _source = sollume.AppTextStyles.build(
    sollume.AppThemeColors.light,
  );
  static TextStyle _inherit(TextStyle source) => TextStyle(
    fontFamily: source.fontFamily,
    fontSize: source.fontSize,
    fontWeight: source.fontWeight,
    height: source.height,
    letterSpacing: source.letterSpacing,
  );
  static TextStyle displayLarge = _inherit(_source.displayLarge!);
  static TextStyle displayMedium = _inherit(_source.displayMedium!);
  static TextStyle displaySmall = _inherit(_source.displaySmall!);
  static TextStyle headlineLarge = _inherit(_source.headlineLarge!);
  static TextStyle headlineMedium = _inherit(_source.headlineMedium!);
  static TextStyle headlineSmall = _inherit(_source.headlineSmall!);
  static TextStyle titleLarge = _inherit(_source.titleLarge!);
  static TextStyle titleMedium = _inherit(_source.titleMedium!);
  static TextStyle titleSmall = _inherit(_source.titleSmall!);
  static TextStyle bodyLarge = _inherit(_source.bodyLarge!);
  static TextStyle bodyMedium = _inherit(_source.bodyMedium!);
  static TextStyle bodySmall = _inherit(_source.bodySmall!);
  static TextStyle labelLarge = _inherit(_source.labelLarge!);
  static TextStyle labelMedium = _inherit(_source.labelMedium!);
  static TextStyle labelSmall = _inherit(_source.labelSmall!);
  /* 6. SPECIAL CULINARY STYLES - Phong cách chuyên biệt cho Ứng dụng Bếp Xinh */
  /* Tên món ăn trong Card thực đơn */
  static TextStyle recipeCardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,

    height: 1.3,
  );

  /* Số thứ tự bước nấu ăn ("Bước 1", "Bước 2") */
  static TextStyle stepNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  /* Tên nguyên liệu ("Thịt ba chỉ", "Hành lá") */
  static TextStyle ingredientName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  /* Định lượng nguyên liệu ("300g", "2 muỗng canh") */
  static TextStyle ingredientAmount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /* Thông tin meta (Thời gian nấu: 30 phút, 4 người ăn, calo) */
  static TextStyle metaText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /* Chữ trên nút bấm chính (Primary Button Text) */
  static TextStyle primaryButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  /* Chữ phụ đề / Slogan ("Nấu ăn ngon - Trọn yêu thương") */
  static TextStyle appSlogan = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
  );

  /* 7. MATERIAL 3 TEXT THEME - Tích hợp toàn diện vào ThemeData */
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  ).apply(fontFamily: fontFamily);
}
