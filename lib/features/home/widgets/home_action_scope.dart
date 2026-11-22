import 'package:flutter/material.dart';

/// Screen cấp hành động điều hướng để AppBar chỉ phụ trách trình bày.
class HomeActionScope extends InheritedWidget {
  final VoidCallback openNotifications;
  final VoidCallback openMessages;
  final VoidCallback? openKitchen;
  const HomeActionScope({
    super.key,
    required this.openNotifications,
    required this.openMessages,
    this.openKitchen,
    required super.child,
  });
  static HomeActionScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeActionScope>()!;
  @override
  bool updateShouldNotify(HomeActionScope oldWidget) =>
      openNotifications != oldWidget.openNotifications ||
      openMessages != oldWidget.openMessages ||
      openKitchen != oldWidget.openKitchen;
}
