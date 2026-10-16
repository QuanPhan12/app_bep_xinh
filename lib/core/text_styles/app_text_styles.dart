import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../colors/app_colors.dart';

/* Hệ thống Typography cho ứng dụng Bếp Xinh (Font Be Vietnam Pro) */
class AppTextStyles {
  const AppTextStyles._();

  /* Tên font chữ */
  static const String fontFamily = 'Be Vietnam Pro';

  /* 1. DISPLAY - Dành cho Splash screen, số đếm lớn, Banner chào mừng */
  static TextStyle displayLarge = GoogleFonts.beVietnamPro(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static TextStyle displayMedium = GoogleFonts.beVietnamPro(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.25,
    height: 1.2,
  );

  static TextStyle displaySmall = GoogleFonts.beVietnamPro(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  /* 2. HEADLINE - Tiêu đề màn hình, tên món ăn nổi bật, Tiêu đề Section */
  static TextStyle headlineLarge = GoogleFonts.beVietnamPro(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle headlineMedium = GoogleFonts.beVietnamPro(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle headlineSmall = GoogleFonts.beVietnamPro(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  /* 3. TITLE - Tên món ăn trong Card, AppBar Title, Dialog, BottomSheet */
  static TextStyle titleLarge = GoogleFonts.beVietnamPro(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static TextStyle titleMedium = GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle titleSmall = GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /* 4. BODY - Nội dung mô tả, từng bước hướng dẫn nấu ăn, đoạn văn */
  static TextStyle bodyLarge = GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.beVietnamPro(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.45,
  );

  /* 5. LABEL - Nút bấm (Button), Tag nguyên liệu, Badge thời gian, Chip */
  static TextStyle labelLarge = GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.beVietnamPro(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  static TextStyle labelSmall = GoogleFonts.beVietnamPro(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 0.3,
  );

  /* 6. SPECIAL CULINARY STYLES - Phong cách chuyên biệt cho Ứng dụng Bếp Xinh */
  /* Tên món ăn trong Card thực đơn */
  static TextStyle recipeCardTitle = GoogleFonts.beVietnamPro(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /* Số thứ tự bước nấu ăn ("Bước 1", "Bước 2") */
  static TextStyle stepNumber = GoogleFonts.beVietnamPro(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  /* Tên nguyên liệu ("Thịt ba chỉ", "Hành lá") */
  static TextStyle ingredientName = GoogleFonts.beVietnamPro(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /* Định lượng nguyên liệu ("300g", "2 muỗng canh") */
  static TextStyle ingredientAmount = GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /* Thông tin meta (Thời gian nấu: 30 phút, 4 người ăn, calo) */
  static TextStyle metaText = GoogleFonts.beVietnamPro(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /* Chữ trên nút bấm chính (Primary Button Text) */
  static TextStyle primaryButton = GoogleFonts.beVietnamPro(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  /* Chữ phụ đề / Slogan ("Nấu ăn ngon - Trọn yêu thương") */
  static TextStyle appSlogan = GoogleFonts.beVietnamPro(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.textSecondary,
  );

  /* 7. MATERIAL 3 TEXT THEME - Tích hợp toàn diện vào ThemeData */
  static TextTheme get textTheme => GoogleFonts.beVietnamProTextTheme(
        TextTheme(
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
        ),
      );
}
