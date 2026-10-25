import 'package:flutter/material.dart';

import '../colors/app_colors.dart';

/// Khung card tách từ ProductCard đang dùng ở Home.
class AppCard extends StatelessWidget {
  static const radius = 12.0;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}
