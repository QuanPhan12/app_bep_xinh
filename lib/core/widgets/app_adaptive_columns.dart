import 'package:flutter/material.dart';

import '../utils/app_layout.dart';

/// One scroll owner outside this widget; each pane keeps its natural height.
class AppAdaptiveColumns extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final double breakpoint;
  final double spacing;
  final int primaryFlex;
  final int secondaryFlex;
  const AppAdaptiveColumns({
    super.key,
    required this.primary,
    required this.secondary,
    this.breakpoint = AppLayout.splitBreakpoint,
    this.spacing = 24,
    this.primaryFlex = 1,
    this.secondaryFlex = 1,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final split = constraints.maxWidth >= breakpoint;
      // Giữ cùng cây widget khi xoay máy để ô nhập không mất focus/controller.
      return Flex(
        direction: split ? Axis.horizontal : Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: split
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.stretch,
        children: [
          Flexible(
            flex: split ? primaryFlex : 0,
            fit: split ? FlexFit.tight : FlexFit.loose,
            child: primary,
          ),
          SizedBox(width: split ? spacing : 0, height: split ? 0 : spacing),
          Flexible(
            flex: split ? secondaryFlex : 0,
            fit: split ? FlexFit.tight : FlexFit.loose,
            child: secondary,
          ),
        ],
      );
    },
  );
}
