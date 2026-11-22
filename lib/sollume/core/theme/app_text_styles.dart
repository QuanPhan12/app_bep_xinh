import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizes.dart';

/*
 * AppTextStyles xây dựng hệ thống kiểu chữ (TextTheme) cho toàn bộ ứng dụng Sollume:
 * - Tiêu đề, nội dung và nhãn dùng Be Vietnam Pro được đóng gói cùng ứng dụng.
 */
abstract final class AppTextStyles {
  static const beVietnamProFontFamily = 'BeVietnamPro';
  static const fontFamily = beVietnamProFontFamily;
  static const bundledFontFamilies = [
    beVietnamProFontFamily,
  ];

  /*
   * Khởi tạo đối tượng TextTheme tương thích Material 3, có hỗ trợ scale kích cỡ chữ
   * tự động theo chiều rộng màn hình trong khoảng an toàn (minUiScale đến maxUiScale).
   */
  static TextTheme build(AppThemeColors c, {double scale = 1}) {
    /* Đảm bảo hệ số scale luôn nằm trong khoảng an toàn (0.90 -> 1.15) */
    final safeScale = scale.clamp(AppSizes.minUiScale, AppSizes.maxUiScale);

    /*
     * Hàm trợ giúp tính cỡ chữ sau khi nhân tỷ lệ màn hình và giới hạn min/max:
     * - Cỡ chữ >= 14px sẽ không bao giờ co nhỏ hơn 14px
     * - Cỡ chữ nhỏ hơn sẽ không co nhỏ hơn 12px
     */
    double font(double base, {double? min, double? max}) => (base * safeScale)
        .clamp(
          min ?? (base >= 14 ? 14.0 : 12.0),
          max ?? base * AppSizes.maxUiScale,
        )
        .toDouble();

    /* Định dạng kiểu chữ nội dung (Be Vietnam Pro) */
    TextStyle body(
      double size, {
      FontWeight weight = FontWeight.w400,
      double height = 1.6,
      Color? color,
      double? min,
      double? max,
    }) => TextStyle(
      fontFamily: fontFamily,
      fontSize: font(size, min: min, max: max),
      fontWeight: weight,
      height: height,
      color: color ?? c.text,
    );

    /* Định dạng kiểu chữ tiêu đề (Be Vietnam Pro) */
    TextStyle heading(
      double size, {
      double height = 1.25,
      double letterSpacing = -0.3,
    }) => TextStyle(
      fontFamily: fontFamily,
      fontSize: font(size, min: size * 0.9),
      fontWeight: FontWeight.w500,
      height: height,
      letterSpacing: letterSpacing,
      color: c.text,
    );

    /*
     * Tỷ lệ co giãn theo chiều rộng CHỈ ĐƯỢC ÁP DỤNG MỘT LẦN DUY NHẤT TẠI ĐÂY.
     * Tuyệt đối không dùng thêm .sp cho các kiểu chữ này để tránh lỗi phóng đại đôi.
     * Cỡ chữ bodyMedium: 14–16px, bodyLarge: 14–18px, thông tin phụ: >= 12px.
     * Flutter sẽ tự động áp dụng TextScaler nguyên bản của hệ điều hành khi render Text.
     */
    return TextTheme(
      /* Các kiểu chữ hiển thị lớn (Display) */
      displayLarge: heading(48, height: 1.1, letterSpacing: -1.5),
      displayMedium: heading(40, height: 1.15, letterSpacing: -1),
      displaySmall: heading(32, height: 1.2, letterSpacing: -0.8),

      /* Các kiểu chữ đầu mục lớn (Headline) */
      headlineLarge: heading(30),
      headlineMedium: heading(28),
      headlineSmall: heading(24),

      /* Các kiểu chữ tiêu đề phần (Title) */
      titleLarge: heading(20, height: 1.5),
      titleMedium: body(16, weight: FontWeight.w500, height: 1.5),
      titleSmall: body(14, weight: FontWeight.w500, height: 1.5),

      /* Các kiểu chữ văn bản nội dung chính (Body) */
      bodyLarge: body(16, min: 14, max: 18),
      bodyMedium: body(15, min: 14, max: 16),
      bodySmall: body(12, color: c.muted),

      /* Các kiểu chữ nhãn nút, form, tab (Label) */
      labelLarge: body(14, weight: FontWeight.w500, height: 1.4),
      labelMedium: body(12, weight: FontWeight.w500, height: 1.4),
      labelSmall: body(12, height: 1.4, color: c.muted),
    );
  }
}
