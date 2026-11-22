import 'package:flutter/widgets.dart';

import 'app_responsive.dart';

/*
 * AppSpacing định nghĩa hệ thống khoảng cách chuẩn (spacing / padding / margin)
 * theo thang 4px để duy trì nhịp điệu thị giác nhất quán trong toàn bộ ứng dụng.
 */
abstract final class AppSpacing {
  /// Chuyển khoảng cách gốc sang logical px theo scale chung của ứng dụng.
  /// Chỉ truyền giá trị chưa scale, ví dụ AppSpacing.sm.
  static double resolve(BuildContext context, double base) {
    assert(base >= 0 && base < double.infinity);
    return AppResponsive.of(context).size(base);
  }

  /* Khoảng cách cực nhỏ (4.0) */
  static const xxs = 4.0;

  /* Khoảng cách rất nhỏ (8.0) */
  static const xs = 8.0;

  /* Khoảng cách nhỏ (12.0) */
  static const sm = 12.0;

  /* Khoảng cách trung bình mặc định (16.0) */
  static const md = 16.0;

  /* Khoảng cách lớn (20.0) */
  static const lg = 20.0;

  /* Khoảng cách rất lớn (24.0) */
  static const xl = 24.0;

  /* Khoảng cách 28.0 */
  static const xxl = 28.0;

  /* Khoảng cách 32.0 */
  static const xxxl = 32.0;

  /* Khoảng cách giữa các khối nội dung lớn / section (40.0) */
  static const section = 40.0;
}
