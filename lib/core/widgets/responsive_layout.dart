import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Widget chuyên dụng điều phối hiển thị bố cục theo thiết bị (Responsive Layout Dispatcher).
/// Cho phép tách biệt hoàn toàn mã nguồn giữa giao diện Mobile và Tablet/Desktop,
/// giúp mã sạch, dễ bảo trì và mở rộng chuẩn Senior.
class ResponsiveLayout extends StatelessWidget {
  /// Giao diện dành riêng cho Mobile (< 600px)
  final Widget mobile;

  /// Giao diện dành riêng cho Tablet (600px - 1024px)
  final Widget? tablet;

  /// Giao diện dành riêng cho Desktop (> 1024px) - Tùy chọn
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (desktop != null && MediaQuery.of(context).size.width >= 1025) {
      return desktop!;
    }
    if (tablet != null && context.isTablet) {
      return tablet!;
    }
    return mobile;
  }
}
