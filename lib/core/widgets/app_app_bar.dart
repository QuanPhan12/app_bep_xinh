import 'dart:async';

import 'package:flutter/material.dart';

import 'app_bar_style.dart';

/// Phiên bản cố định của AppBar chuẩn ở màn đăng ký tài khoản.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final FutureOr<void> Function()? onBack;
  final List<Widget>? actions;
  final bool backEnabled;
  final bool automaticallyImplyLeading;

  const AppAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.backEnabled = true,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final style = AppBarStyle();
    return AppBar(
      title: style.title(title),
      centerTitle: true,
      automaticallyImplyLeading: false,
      backgroundColor: style.background,
      foregroundColor: style.foreground,
      flexibleSpace: style.flexibleSpace(null),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: style.overlay,
      iconTheme: IconThemeData(color: style.foreground),
      actionsIconTheme: IconThemeData(color: style.foreground),
      leading:
          onBack != null || (automaticallyImplyLeading && appBarCanPop(context))
          ? AppBarBackButton(
              style: style,
              enabled: backEnabled,
              onBack: onBack ?? () => appBarPop(context),
            )
          : null,
      actions: actions,
    );
  }
}
