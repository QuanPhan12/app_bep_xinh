/*
 * AppSizes chứa các hằng số kích thước chuẩn, breakpoint màn hình,
 * và logic tính toán lề (gutter) responsive cho ứng dụng Sollume.
 */
abstract final class AppSizes {
  /*
   * Kích thước chuẩn thiết kế (logical pixels).
   * Lưu ý: Chiều cao (height) KHÔNG được dùng để co giãn text hay UI,
   * việc co giãn chỉ phụ thuộc vào chiều rộng (width).
   */
  static const designWidth = 390.0;
  static const designHeight = 844.0;

  /* Giới hạn tỷ lệ co giãn giao diện (scale tối thiểu 90%, tối đa 115%) */
  static const minUiScale = 0.90;
  static const maxUiScale = 1.15;

  /* Điểm ngắt màn hình (Breakpoints) */
  static const tabletBreakpoint = 600.0;
  static const desktopBreakpoint = 960.0;

  /* Độ rộng tối đa của cột nội dung chính (Content Rail) */
  static const contentRail = 760.0;
  static const wideContent = 1200.0;
  static const dialogWidth = 480.0;

  /* Khoảng cách lề (gutter) theo từng kích cỡ màn hình */
  static const tabletGutter = 32.0;
  static const mobileGutter = 16.0;
  static const smallMobileGutter = 12.0;

  /* Nét phân cách dùng chung cho list, AppBar, navigation và footer. */
  static const dividerThickness = 0.5;

  /* Độ rộng tối đa cho khối form xác thực (Auth Form) */
  static const authWidth = 456.0;

  /* Chiều cao chuẩn của các phần tử tương tác */
  static const buttonHeight = 48.0;
  static const fieldHeight = 48.0;
  static const navigationHeight = 68.0;
  static const navigationSidebarWidth = 220.0;
  static const navigationSidebarMaxWidth = 280.0;
  static const navigationSidebarCollapsedWidth = 80.0;
  static const minTouchTarget = 48.0;
  static const minTouchTargetSmall = 40.0;
  static const minTouchTargetTiny = 24.0;
  static const minPageContentWidth = 320.0;

  /*
   * Xác định độ rộng khoảng cách lề (gutter) tự động dựa trên chiều rộng màn hình:
   * - Màn hình tablet (>= 600px): 32px
   * - Màn hình điện thoại nhỏ (< 360px): 12px
   * - Màn hình điện thoại thông thường: 16px
   */
  static double gutter(double width) => width >= tabletBreakpoint
      ? tabletGutter
      : width < 360
      ? smallMobileGutter
      : mobileGutter;
}
