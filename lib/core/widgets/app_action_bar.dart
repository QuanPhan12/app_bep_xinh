import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../constants/app_constants.dart';

/// Khung thanh hành động tách từ Đăng món; nội dung nút do feature truyền vào.
class AppActionBar extends StatelessWidget {
  final Widget child;
  const AppActionBar({super.key, required this.child});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        ),
      ),
    ),
  );
}
