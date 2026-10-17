import 'package:flutter/material.dart';

/// Lớp trung tâm tính toán và cung cấp kích thước tự động thích ứng (Responsive Sizing)
/// cho mọi widget trong toàn ứng dụng Bếp Xinh.
///
/// Giải quyết triệt để vấn đề:
/// - Máy màn hình dài (như Vivo) vs máy màn hình ngắn/bị zoom to (như Samsung)
/// - Máy nhỏ (Small mobile) vs máy tiêu chuẩn vs Máy tính bảng (Tablet)
/// - Không để widget bị phình to hoặc lọt thỏm không đều nhau giữa các dòng máy.
class AppSize {
  final BuildContext context;
  late final double screenWidth;
  late final double screenHeight;
  late final double shortestSide;
  late final double longestSide;
  late final double devicePixelRatio;
  late final double textScale;
  late final double topPadding;
  late final double bottomPadding;

  /// Chuẩn thiết kế gốc (Figma chuẩn cho Mobile hiện đại: 390 x 844)
  static const double baseWidth = 390.0;
  static const double baseHeight = 844.0;

  AppSize._(this.context) {
    final media = MediaQuery.of(context);
    screenWidth = media.size.width;
    screenHeight = media.size.height;
    shortestSide = media.size.shortestSide;
    longestSide = media.size.longestSide;
    devicePixelRatio = media.devicePixelRatio;
    textScale = media.textScaler.scale(1.0);
    topPadding = media.padding.top;
    bottomPadding = media.padding.bottom;
  }

  /// Khởi tạo và lấy instance AppSize theo BuildContext hiện tại
  static AppSize of(BuildContext context) => AppSize._(context);

  // ==========================================
  // PHÂN LOẠI THIẾT BỊ THỰC TẾ
  // ==========================================

  /// Điện thoại nhỏ hoặc bị bật Screen Zoom lớn (chiều ngang hẹp < 360dp)
  bool get isSmallMobile => shortestSide < 360;

  /// Điện thoại tiêu chuẩn (360dp <= shortestSide < 600dp)
  bool get isStandardMobile => shortestSide >= 360 && shortestSide < 600;

  /// Máy tính bảng hoặc màn hình lớn (>= 600dp)
  bool get isTablet => shortestSide >= 600;

  // ==========================================
  // HỆ SỐ CO GIÃN THÔNG MINH (DAMPED SCALE FACTOR)
  // ==========================================

  /// Hệ số co giãn ngang có giảm chấn để tránh bị phóng đại quá mức
  double get scaleFactorW {
    if (isTablet) {
      // Trên Tablet không phóng to vô tội vạ, giữ trong mức 1.15 -> 1.25
      return 1.15 + ((shortestSide - 600) / 2000).clamp(0.0, 0.15);
    }
    if (isSmallMobile) {
      // Máy nhỏ/zoom to: Giảm nhẹ tỷ lệ (0.88 -> 0.95) để tránh widget phình to dày cộp
      return (shortestSide / baseWidth).clamp(0.88, 0.96);
    }
    // Máy chuẩn (Vivo, iPhone, Samsung chuẩn): dao động 0.95 -> 1.08
    return (shortestSide / baseWidth).clamp(0.95, 1.08);
  }

  /// Hệ số co giãn dọc tính theo tỷ lệ chiều cao
  double get scaleFactorH {
    if (isTablet) {
      return 1.15;
    }
    if (screenHeight < 700) {
      // Máy có chiều cao thấp (dưới 700dp): Giảm nhẹ chiều cao widget để không chiếm hết màn
      return 0.92;
    }
    if (screenHeight > 900) {
      // Máy siêu dài (tỷ lệ 20:9, 20.5:9 như nhiều máy Vivo): Giữ ổn định không kéo dãn
      return 1.02;
    }
    return (screenHeight / baseHeight).clamp(0.94, 1.06);
  }

  // ==========================================
  // CÁC HÀM TÍNH TOÁN KÍCH THƯỚC ĐỘNG
  // ==========================================

  /// Tính chiều cao động thích ứng (Height)
  /// Ví dụ: h(50) trên máy nhỏ sẽ ra ~46, máy chuẩn ra 50, tablet ra ~58
  double h(double designHeight, {double? min, double? max}) {
    final calculated = designHeight * scaleFactorH;
    final minLimit = min ?? (designHeight * 0.85);
    final maxLimit =
        max ?? (isTablet ? designHeight * 1.3 : designHeight * 1.15);
    return calculated.clamp(minLimit, maxLimit);
  }

  /// Tính chiều rộng động thích ứng (Width)
  double w(double designWidth, {double? min, double? max}) {
    final calculated = designWidth * scaleFactorW;
    final minLimit = min ?? (designWidth * 0.85);
    final maxLimit = max ?? (isTablet ? designWidth * 1.4 : designWidth * 1.2);
    return calculated.clamp(minLimit, maxLimit);
  }

  /// Tính cỡ chữ an toàn (Font Size)
  /// Tự động kìm hãm khi người dùng tăng font chữ hệ điều hành quá to
  double sp(double designFontSize, {double? min, double? max}) {
    final calculated = designFontSize * scaleFactorW;
    final minLimit = min ?? (designFontSize * 0.9);
    final maxLimit = max ?? (designFontSize * 1.2);
    return calculated.clamp(minLimit, maxLimit);
  }

  /// Tính bán kính bo góc (Border Radius)
  double r(double designRadius) {
    if (isSmallMobile) return (designRadius * 0.9).roundToDouble();
    if (isTablet) return (designRadius * 1.2).roundToDouble();
    return designRadius;
  }

  // ==========================================
  // CÁC TOKEN KÍCH THƯỚC CHUẨN HÓA DÙNG CHUNG
  // ==========================================

  /// Chiều cao nút bấm (Button Height) chuẩn toàn app:
  /// - Máy nhỏ (Samsung zoom to): 46
  /// - Máy chuẩn (Vivo, iPhone): 50
  /// - Tablet: 58
  double get buttonHeight {
    if (isSmallMobile) return 58.0;
    if (isTablet) return 58.0;
    return 50.0;
  }

  /// Chiều cao nút bấm nhỏ (Small Button)
  double get buttonHeightSmall => isTablet ? 44.0 : 38.0;

  /// Chiều cao ô nhập liệu (Text Field / Search bar Height)
  double get inputHeight {
    if (isSmallMobile) return 58.0;
    if (isTablet) return 58.0;
    return 50.0;
  }

  /// Kích thước icon chuẩn
  double get iconSmall => isTablet ? 20.0 : 16.0;
  double get iconMedium => isTablet ? 28.0 : 22.0;
  double get iconLarge => isTablet ? 36.0 : 28.0;

  /// Khoảng cách căn lề hai bên màn hình (Screen Horizontal Padding)
  double get screenPaddingHorizontal {
    if (isTablet) return 36.0;
    if (isSmallMobile) return 16.0;
    return 20.0;
  }

  /// Khoảng cách padding trong thẻ Card
  double get cardPadding {
    if (isTablet) return 20.0;
    if (isSmallMobile) return 12.0;
    return 16.0;
  }

  /// Khoảng cách Spacing chuẩn:
  double get space4 => 4.0 * scaleFactorW;
  double get space8 => 8.0 * scaleFactorW;
  double get space12 => 12.0 * scaleFactorW;
  double get space16 => 16.0 * scaleFactorW;
  double get space20 => 20.0 * scaleFactorW;
  double get space24 => 24.0 * scaleFactorW;
  double get space32 => 32.0 * scaleFactorW;
}

/// Các tiện ích mở rộng (Extension) giúp gọi AppSize cực ngắn gọn
extension AppSizeContextExtension on BuildContext {
  /// Truy cập nhanh AppSize của context
  AppSize get appSize => AppSize.of(this);

  /// Tính chiều cao thích ứng: `context.h(50)`
  double h(double value, {double? min, double? max}) =>
      appSize.h(value, min: min, max: max);

  /// Tính chiều rộng thích ứng: `context.w(100)`
  double w(double value, {double? min, double? max}) =>
      appSize.w(value, min: min, max: max);

  /// Tính cỡ chữ thích ứng: `context.sp(16)`
  double sp(double value, {double? min, double? max}) =>
      appSize.sp(value, min: min, max: max);

  /// Tính bo góc thích ứng: `context.r(12)`
  double r(double value) => appSize.r(value);
}

/// Extension trực tiếp trên số thực `num`:
/// `50.h(context)` hoặc `16.sp(context)`
extension AppSizeNumExtension on num {
  double h(BuildContext context, {double? min, double? max}) =>
      context.h(toDouble(), min: min, max: max);

  double w(BuildContext context, {double? min, double? max}) =>
      context.w(toDouble(), min: min, max: max);

  double sp(BuildContext context, {double? min, double? max}) =>
      context.sp(toDouble(), min: min, max: max);

  double r(BuildContext context) => context.r(toDouble());
}
