import 'package:flutter/material.dart';

import '../dimensions/app_ui.dart';

/// Khung card tách từ ProductCard đang dùng ở Home.
class AppCard extends StatelessWidget {
  final double radius;
  final bool showBorder;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = AppUi.cardRadius,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: showBorder
          ? BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant
                  .withValues(alpha: .45),
            )
          : BorderSide.none,
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}
