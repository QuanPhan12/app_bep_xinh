import 'package:flutter/material.dart';

/// Danh sách nội dung dạng sliver; không tự thêm AppBar hoặc SafeArea.
class AppContentScrollView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  const AppContentScrollView({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.physics,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
  });

  @override
  Widget build(BuildContext context) => CustomScrollView(
    physics: physics,
    keyboardDismissBehavior: keyboardDismissBehavior,
    slivers: [
      SliverPadding(
        padding: padding,
        sliver: SliverList.list(children: children),
      ),
    ],
  );
}
