import 'package:flutter/material.dart';

/// Giới hạn bề ngang nội dung trên tablet nhưng giữ AppBar phủ hết màn hình.
class AppSliverContent extends StatelessWidget {
  final double maxWidth;
  final List<Widget> slivers;

  const AppSliverContent({
    super.key,
    required this.maxWidth,
    required this.slivers,
  });

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) => SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: ((constraints.crossAxisExtent - maxWidth) / 2).clamp(
          0,
          double.infinity,
        ),
      ),
      sliver: SliverMainAxisGroup(slivers: slivers),
    ),
  );
}
