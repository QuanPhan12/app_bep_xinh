import 'package:flutter/material.dart';

import '../colors/app_colors.dart';

/// Chấm đỏ thông báo chưa đọc, không thay đổi kích thước vùng bấm của icon.
class AppUnreadIndicator extends StatelessWidget {
  final bool hasUnread;
  final String unreadLabel;
  final Widget child;

  const AppUnreadIndicator({
    super.key,
    required this.hasUnread,
    required this.unreadLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: hasUnread ? unreadLabel : null,
    child: Badge(
      isLabelVisible: hasUnread,
      backgroundColor: context.colors.error,
      smallSize: 8,
      child: child,
    ),
  );
}
