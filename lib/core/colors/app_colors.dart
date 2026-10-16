import 'package:flutter/material.dart';

/* Bộ màu sắc (Design System Colors) cho ứng dụng Bếp Xinh */
class AppColors {
  const AppColors._();

  /* 1. PRIMARY PALETTE - Sắc độ màu chủ đạo #E8590C */
  /* Màu thương hiệu chính (Base Primary) - Thổi bùng cảm giác ngon miệng, ấm cúng */
  static const Color primary = Color(0xFFE8590C);

  /* Thang sắc độ */
  static const Color primary50 = Color(0xFFFFF4E6); /* Nền chip, badge, highlight nhẹ */
  static const Color primary100 = Color(0xFFFFE8CC); /* Border active, badge nhạt */
  static const Color primary200 = Color(0xFFFFD8A8); /* Container tint */
  static const Color primary300 = Color(0xFFFFA94D); /* Hover state / secondary button */
  static const Color primary400 = Color(0xFFFF922B); /* Lighter primary */
  static const Color primary500 = Color(0xFFE8590C); /* Base Primary */
  static const Color primary600 = Color(0xFFD9480F); /* Pressed state */
  static const Color primary700 = Color(0xFFBF4006); /* Deep contrast */
  static const Color primary800 = Color(0xFFA33605);
  static const Color primary900 = Color(0xFF7A2804);

  /* 2. SECONDARY & ACCENT - Phối màu ẩm thực & biểu tượng Logo Bếp Xinh */
  /* Màu phụ: Xanh thảo mộc / rau củ tươi (Đồng điệu với lá xanh trên logo) */
  static const Color secondary = Color(0xFF2B8A3E);
  static const Color secondaryLight = Color(0xFFEBFBEE);
  static const Color secondaryDark = Color(0xFF237032);

  /* Màu điểm nhấn: Vàng hổ phách / gia vị (Dành cho sao đánh giá rating, bookmark, highlight) */
  static const Color accent = Color(0xFFFAB005);
  static const Color accentLight = Color(0xFFFFF9DB);

  /* 3. NEUTRAL & SURFACE - Nền, thẻ card, thanh phân cách */
  /* Nền màn hình (Warm off-white) */
  static const Color background = Color(0xFFF8F9FA);

  /* Màu nền thẻ (Card, Modal, BottomSheet) */
  static const Color surface = Colors.white;

  /* Màu nền phụ (Search bar, input field nền xám nhẹ) */
  static const Color surfaceVariant = Color(0xFFF1F3F5);

  /* Đường viền (Border & Divider) */
  static const Color border = Color(0xFFE9ECEF);
  static const Color borderLight = Color(0xFFF8F9FA);
  static const Color borderDark = Color(0xFFCED4DA);

  /* 4. TEXT COLORS - Hệ màu chữ rõ ràng, chuẩn tương phản */
  /* Chữ chính (Tiêu đề, tên món ăn, nội dung quan trọng) */
  static const Color textPrimary = Color(0xFF212529);

  /* Chữ phụ (Mô tả món, tác giả, phụ lục) */
  static const Color textSecondary = Color(0xFF495057);

  /* Chữ mờ (Thời gian nấu, số calo, placeholder) */
  static const Color textTertiary = Color(0xFF868E96);

  /* Chữ disabled / icon inactive */
  static const Color textMuted = Color(0xFFADB5BD);

  /* Chữ màu trắng (Hiển thị trên nền Primary hoặc ảnh tối) */
  static const Color textWhite = Colors.white;

  /* 5. SEMANTIC / STATUS COLORS - Trạng thái hệ thống */
  /* Thành công (Hoàn thành món ăn, đã lưu, kết nối mạng) */
  static const Color success = Color(0xFF2B8A3E);
  static const Color successBg = Color(0xFFEBFBEE);

  /* Cảnh báo (Lưu ý bước nấu ăn, món cay, hết nguyên liệu) */
  static const Color warning = Color(0xFFF59F00);
  static const Color warningBg = Color(0xFFFFF9DB);

  /* Báo lỗi (Lỗi tải công thức, validate form, cảnh báo dị ứng) */
  static const Color error = Color(0xFFE03131);
  static const Color errorBg = Color(0xFFFFF5F5);

  /* Thông tin (Tips mẹo vặt, gợi ý dinh dưỡng) */
  static const Color info = Color(0xFF1971C2);
  static const Color infoBg = Color(0xFFE7F5FF);

  /* 6. GRADIENTS - Dải màu tạo điểm nhấn cho Button, Banner, Header */
  /* Gradient cam ấm áp đặc trưng cho nút hành động chính (Primary Button) */
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF922B), Color(0xFFE8590C)],
  );

  /* Gradient hoàng hôn (Sunset) rực rỡ cho Hero Banner / Card khuyến mãi */
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFE8590C)],
  );

  /* Gradient nhẹ nhàng cho nền Header hoặc Card đặc biệt */
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF4E6), Colors.white],
  );

  /* 7. MATERIAL 3 COLOR SCHEME - Tương thích chuẩn Flutter ThemeData */
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: primary50,
    onPrimaryContainer: primary900,
    secondary: secondary,
    onSecondary: Colors.white,
    secondaryContainer: secondaryLight,
    onSecondaryContainer: secondaryDark,
    tertiary: accent,
    onTertiary: Colors.black,
    error: error,
    onError: Colors.white,
    errorContainer: errorBg,
    onErrorContainer: error,
    surface: surface,
    onSurface: textPrimary,
    surfaceContainerHighest: surfaceVariant,
    onSurfaceVariant: textSecondary,
    outline: borderDark,
    outlineVariant: border,
  );
}
