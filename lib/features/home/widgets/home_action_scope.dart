import 'package:flutter/material.dart';

/// Screen cấp hành động điều hướng để AppBar chỉ phụ trách trình bày.
class HomeActionScope extends InheritedWidget {
  final VoidCallback openNotifications;
  final VoidCallback openMessages;
  final VoidCallback? openKitchen;
  final VoidCallback? openQuickRecipes, openFridge, openFollowing;
  const HomeActionScope({
    super.key,
    required this.openNotifications,
    required this.openMessages,
    this.openKitchen,
    this.openQuickRecipes,
    this.openFridge,
    this.openFollowing,
    required super.child,
  });
  static HomeActionScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeActionScope>()!;
  @override
  bool updateShouldNotify(HomeActionScope oldWidget) =>
      openNotifications != oldWidget.openNotifications ||
      openMessages != oldWidget.openMessages ||
      openKitchen != oldWidget.openKitchen ||
      openQuickRecipes != oldWidget.openQuickRecipes ||
      openFridge != oldWidget.openFridge ||
      openFollowing != oldWidget.openFollowing;
}
