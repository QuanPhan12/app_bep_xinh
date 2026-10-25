import 'package:flutter/material.dart';

import 'app_layout.dart';

/// Tiện ích hỗ trợ responsive toàn diện cho ứng dụng Bếp Xinh
class ResponsiveUtils {
  const ResponsiveUtils._();

  /// Kiểm tra thiết bị hiện tại có phải là Tablet không (hoặc màn hình lớn >= 600px)
  static bool isTablet(BuildContext context) {
    return AppLayout.isTablet(context);
  }

  /// Kiểm tra thiết bị hiện tại có phải là Mobile không (< 600px)
  static bool isMobile(BuildContext context) {
    return !isTablet(context);
  }
}

/// Extension tiện lợi trên BuildContext để check responsive nhanh
extension ResponsiveContextExtension on BuildContext {
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isMobile => ResponsiveUtils.isMobile(this);
}
