import 'package:flutter/material.dart';

/// Không để tooltip giữ overlay khi route bị che hoặc tab ngừng hoạt động.
/// Flutter 3.47.2 có thể giữ overlay offstage với kích thước cũ khi resize:
/// https://github.com/flutter/flutter/issues/192030
class AppRouteTooltipScope extends StatelessWidget {
  const AppRouteTooltipScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TooltipVisibility(
    visible:
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true),
    child: child,
  );
}
