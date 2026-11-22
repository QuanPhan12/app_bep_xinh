import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../utils/app_layout.dart';

/// Khung thanh hành động tách từ Đăng món; nội dung nút do feature truyền vào.
class AppActionBar extends StatelessWidget {
  final Widget child;
  const AppActionBar({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.surface,
      border: Border(top: BorderSide(color: context.colors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppLayout.formWidth(context)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        ),
      ),
    ),
  );
}
