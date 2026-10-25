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
      if (constraints.maxWidth < breakpoint) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            primary,
            SizedBox(height: spacing),
            secondary,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: primaryFlex, child: primary),
          SizedBox(width: spacing),
          Expanded(flex: secondaryFlex, child: secondary),
        ],
      );
    },
  );
}
