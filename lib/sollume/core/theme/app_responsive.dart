import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../interaction/app_route_tooltip_scope.dart';
import 'app_sizes.dart';

/*
 * AppResponsive quản lý toàn bộ logic tính toán responsive của ứng dụng:
 * - Co giãn (scale) CHỈ dựa theo chiều rộng (width).
 * - Chiều cao (height), mật độ điểm ảnh vật lý hay tên thiết bị không ảnh hưởng đến tỷ lệ scale.
 * - TextScaler của hệ thống được giữ nguyên vẹn để người dùng chỉnh cỡ chữ trợ năng tùy ý.
 */
@immutable
class AppResponsive {
  const AppResponsive._(this.width, this.scale);

  /*
   * Khởi tạo thông số AppResponsive dựa trên độ rộng màn hình thực tế (width).
   * Tỷ lệ scale được tính bằng: width / designWidth (390px),
   * giới hạn an toàn trong khoảng minUiScale (0.90) đến maxUiScale (1.15).
   */
  factory AppResponsive.fromWidth(double width) {
    if (!width.isFinite || width < 0) {
      throw ArgumentError.value(
        width,
        'width',
        'Chiều rộng phải hữu hạn và không âm',
      );
    }
    return AppResponsive._(
      width,
      (width / AppSizes.designWidth)
          .clamp(AppSizes.minUiScale, AppSizes.maxUiScale)
          .toDouble(),
    );
  }

  /* Chiều rộng hiện tại của màn hình / container (logical px) */
  final double width;

  /* Hệ số co giãn tương ứng */
  final double scale;

  /* Màn hình nhỏ (điện thoại): width < 600px */
  bool get isCompact => width < AppSizes.tabletBreakpoint;

  /* Màn hình trung bình (máy tính bảng / tablet): 600px <= width < 960px */
  bool get isMedium =>
      width >= AppSizes.tabletBreakpoint && width < AppSizes.desktopBreakpoint;

  /* Màn hình lớn (máy tính để bàn / desktop): width >= 960px */
  bool get isExpanded => width >= AppSizes.desktopBreakpoint;

  /* Khoảng cách lề (gutter) tương ứng với độ rộng hiện tại */
  double get gutter => AppSizes.gutter(width);

  /*
   * Lấy dữ liệu AppResponsive từ InheritedWidget gần nhất hoặc từ MediaQuery root.
   * Để đo kích thước một phân vùng cục bộ, hãy dùng LayoutBuilder.
   */
  static AppResponsive of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ResponsiveScope>()?.data ??
      AppResponsive.fromWidth(MediaQuery.sizeOf(context).width);

  /// Đọc chiều rộng container khi có giới hạn; chỉ fallback viewport nếu unbounded.
  /// Web resize và panel hẹp dùng chung một cách đo, không scale theo tên thiết bị.
  static AppResponsive forConstraints(
    BuildContext context,
    BoxConstraints constraints,
  ) => AppResponsive.fromWidth(
    constraints.hasBoundedWidth
        ? constraints.maxWidth
        : MediaQuery.sizeOf(context).width,
  );

  /*
   * Co giãn kích thước icon, khoảng cách, hình minh họa nhỏ.
   * Lưu ý: Không truyền vào giá trị đã được scale từ trước.
   */
  double size(double base, {double? min, double? max}) => (base * scale)
      .clamp(
        min ?? base * AppSizes.minUiScale,
        max ?? base * AppSizes.maxUiScale,
      )
      .toDouble();

  /*
   * Đảm bảo phần tử tương tác (button, input, tap target)
   * không bao giờ co nhỏ hơn kích thước chuẩn 48 logical px.
   */
  double control(double base) => math.max(48.0, size(base));

  /*
   * Tính toán số lượng cột hiển thị trong một lưới (grid) co giãn,
   * dựa trên độ rộng tối thiểu của mỗi item và khoảng cách giữa các item.
   */
  int columns({required double minItemWidth, double gap = 16, int max = 6}) {
    if (minItemWidth <= 0 || gap < 0 || max < 1) {
      throw ArgumentError('Kích thước lưới không hợp lệ');
    }
    return ((width + gap) / (minItemWidth + gap)).floor().clamp(1, max).toInt();
  }
}

/*
 * Kiểu hàm builder truyền context, thông số responsive metrics và widget con.
 */
typedef AppResponsiveThemeBuilder = Widget Function(
  BuildContext context,
  AppResponsive metrics,
  Widget child,
);

/*
 * AppResponsiveInit được gọi từ AppTheme.builder, nằm BÊN DƯỚI MediaQuery của MaterialApp.
 * Không bọc thêm ScreenUtilInit hay ResponsiveScaledBox bên ngoài widget này.
 */
class AppResponsiveInit extends StatelessWidget {
  const AppResponsiveInit({
    super.key,
    required this.child,
    required this.builder,
  });
  final Widget child;
  final AppResponsiveThemeBuilder builder;

  @override
  Widget build(BuildContext context) => ScreenUtilInit(
    designSize: const Size(AppSizes.designWidth, AppSizes.designHeight),
    minTextAdapt: false,
    splitScreenMode: true,
    fontSizeResolver: (base, instance) =>
        base.toDouble() *
        instance.scaleWidth
            .clamp(AppSizes.minUiScale, AppSizes.maxUiScale)
            .toDouble(),
    child: child,
    builder: (context, navigator) => LayoutBuilder(
      builder: (context, constraints) {
        final metrics = AppResponsive.forConstraints(context, constraints);
        final width = metrics.width;

        /*
         * Xử lý các kích thước phân số ngay sát ngưỡng 600px / 960px
         * (ví dụ: khi co kéo cửa sổ máy tính xuống 599.5px).
         */
        final compactEnd = metrics.isCompact ? math.max(599.0, width) : 599.0;
        final mediumEnd = metrics.isMedium ? math.max(959.0, width) : 959.0;
        final breakpoints = <Breakpoint>[
          Breakpoint(start: 0, end: compactEnd, name: MOBILE),
          Breakpoint(start: 600, end: mediumEnd, name: TABLET),
          const Breakpoint(start: 960, end: double.infinity, name: DESKTOP),
        ];
        return ResponsiveBreakpoints.builder(
          breakpoints: breakpoints,
          useShortestSide: false,
          child: _ResponsiveScope(
            data: metrics,
            child: Builder(
              builder: (context) => builder(
                context,
                metrics,
                navigator ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/*
 * InheritedWidget lưu trữ và truyền AppResponsive xuống toàn bộ cây widget con.
 */
class _ResponsiveScope extends InheritedWidget {
  const _ResponsiveScope({required this.data, required super.child});
  final AppResponsive data;
  @override
  bool updateShouldNotify(_ResponsiveScope oldWidget) =>
      data.width != oldWidget.data.width || data.scale != oldWidget.data.scale;
}

/*
 * AppResponsiveLayout lựa chọn giao diện dựa trên ràng buộc kích thước cục bộ (local constraints)
 * thay vì kích thước toàn màn hình của thiết bị. Ví dụ: một khung bên (side panel) hẹp trên iPad
 * vẫn sẽ tự động chọn giao diện compact thay vì expanded.
 */
class AppResponsiveLayout extends StatelessWidget {
  const AppResponsiveLayout({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  /* Giao diện cho màn hình nhỏ (điện thoại hoặc khung hẹp) */
  final WidgetBuilder compact;

  /* Giao diện cho màn hình vừa (máy tính bảng / 2 cột) */
  final WidgetBuilder? medium;

  /* Giao diện cho màn hình lớn (máy tính để bàn / đa cột) */
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = AppResponsive.forConstraints(context, constraints);
      final selected = layout.isExpanded
          ? expanded ?? medium ?? compact
          : layout.isMedium
          ? medium ?? compact
          : compact;
      return selected(context);
    },
  );
}

/*
 * AppContent bọc phần thân nội dung và giới hạn độ rộng tối đa (mặc định 760px).
 * Tự động căn giữa trang và gắn lề hai bên (24px trên mobile, 32px trên tablet).
 * Chú ý: Việc cuộn (scrolling) thuộc trách nhiệm của màn hình gọi nó
 * (ví dụ bọc bên ngoài bằng SafeArea và SingleChildScrollView).
 */
class AppContent extends StatelessWidget {
  const AppContent({
    super.key,
    required this.child,
    this.maxWidth = AppSizes.contentRail,
    this.maxHeight,
    this.padding,
  }) : assert(maxWidth > 0 && maxWidth < double.infinity);

  /* Widget nội dung bên trong */
  final Widget child;

  /* Độ rộng tối đa của khối (mặc định 760px, với form xác thực có thể dùng authWidth: 456px) */
  final double maxWidth;

  
  //chiều cao
  final double? maxHeight;

  /* Khoảng cách đệm tùy biến (nếu để null sẽ tự lấy theo gutter chuẩn) */
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => AppRouteTooltipScope(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight ?? double.infinity),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding:
                    padding ??
                    EdgeInsets.symmetric(
                      horizontal: AppSizes.gutter(math.min(width, maxWidth)),
                      vertical: 24,
                    ),
                child: child,
              ),
            ),
          ),
        );
      },
    ),
  );
}
