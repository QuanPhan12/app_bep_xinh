import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../dimensions/app_size.dart';

/// Khung card tách từ ProductCard đang dùng ở Home.
class AppCard extends StatelessWidget {
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
      borderRadius: BorderRadius.circular(16.r(context)),
      border: Border.all(color: AppColors.border, width: .8),
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
