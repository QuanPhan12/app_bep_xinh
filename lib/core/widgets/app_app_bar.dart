import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../text_styles/app_text_styles.dart';
import 'app_tap.dart';

/// AppBar phẳng dùng chung cho các màn chi tiết/form của app.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final FutureOr<void> Function()? onBack;
  final List<Widget>? actions;
  final bool backEnabled;

  const AppAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.backEnabled = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(title, style: AppTextStyles.titleLarge),
    centerTitle: false,
    automaticallyImplyLeading: false,
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: onBack == null && !(ModalRoute.of(context)?.canPop ?? false)
        ? null
        : Tooltip(
            message: 'Quay lại',
            child: Semantics(
              button: true,
              label: 'Quay lại',
              child: AppTap(
                actionName: 'app_bar_back',
                allowConcurrent: true,
                onTap: !backEnabled
                    ? null
                    : onBack ?? () => Navigator.of(context).maybePop(),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.arrow_left,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
    actions: actions,
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(height: 1, color: AppColors.border),
    ),
  );
}
