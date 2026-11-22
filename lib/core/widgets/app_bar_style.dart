import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../colors/app_colors.dart';
import '../text_styles/app_text_styles.dart';
import '../tap/app_tap_handler.dart';

/// Chuẩn từ màn đăng ký, dùng chung cho AppBar cố định và SliverAppBar.
class AppBarStyle {
  final Gradient? gradient;
  final Color background;
  final Color foreground;

  AppBarStyle({
    Color? backgroundColor,
    Gradient? gradient,
    Color? foregroundColor,
  }) : gradient = gradient,
       background = gradient != null
           ? Colors.transparent
           : backgroundColor ?? AppColors.background,
       foreground =
           foregroundColor ??
           ((gradient != null) ? Colors.white : AppColors.textPrimary);

  SystemUiOverlayStyle get overlay =>
      (gradient != null ||
                  (background != Colors.transparent &&
                      ThemeData.estimateBrightnessForColor(background) ==
                          Brightness.dark)
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent);

  Widget title(String value) => Text(
    value,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: AppTextStyles.titleLarge.copyWith(
      fontWeight: FontWeight.bold,
      color: foreground,
    ),
  );

  Widget? flexibleSpace(Widget? content) {
    final fill = gradient;
    if (fill == null) return content;
    final background = SizedBox.expand(
      child: DecoratedBox(decoration: BoxDecoration(gradient: fill)),
    );
    if (content == null) return background;
    return Stack(fit: StackFit.expand, children: [background, content]);
  }
}

bool appBarCanPop(BuildContext context) =>
    (GoRouter.maybeOf(context)?.canPop() ?? false) ||
    (ModalRoute.of(context)?.canPop ?? false);

Future<void> appBarPop(BuildContext context) async {
  final router = GoRouter.maybeOf(context);
  if (router?.canPop() ?? false) {
    router!.pop();
  } else {
    await Navigator.of(context).maybePop();
  }
}

class AppBarBackButton extends StatelessWidget {
  final AppBarStyle style;
  final FutureOr<void> Function() onBack;
  final bool enabled;
  const AppBarBackButton({
    super.key,
    required this.style,
    required this.onBack,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Quay lại',
    icon: const PhosphorIcon(PhosphorIconsBold.caretLeft),
    // Màn nền ảnh/gradient vẫn cần foreground tương phản; màn thường dùng theme Sollume.
    color: style.gradient == null ? null : style.foreground,
    onPressed: enabled
        ? AppTapHandler.wrap(
            context,
            onTap: onBack,
            actionName: 'app_bar_back',
            allowConcurrent: true,
          )
        : null,
  );
}
