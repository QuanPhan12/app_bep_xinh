import 'package:flutter/widgets.dart';

import 'app_motion.dart';

enum AppSwitcherTransition { fade, fadeThrough }

/// Đặt key khác nhau cho các nội dung cần chuyển đổi; không bọc ô nhập liệu.
class AppAnimatedSwitcher extends StatelessWidget {
  const AppAnimatedSwitcher({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
    this.transition = AppSwitcherTransition.fade,
  });

  final Widget child;
  final AlignmentGeometry alignment;
  final AppSwitcherTransition transition;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppMotion.durationOf(context, AppMotion.fast),
    switchInCurve: transition == AppSwitcherTransition.fadeThrough
        ? Curves.linear
        : AppMotion.enterCurve,
    switchOutCurve: transition == AppSwitcherTransition.fadeThrough
        ? Curves.linear
        : AppMotion.exitCurve,
    transitionBuilder: (child, animation) => FadeTransition(
      // Cùng timeline: nội dung cũ tắt ở nửa đầu, nội dung mới hiện ở nửa sau.
      opacity: transition == AppSwitcherTransition.fadeThrough
          ? animation.drive(
              CurveTween(
                curve: const Interval(0.5, 1, curve: AppMotion.enterCurve),
              ),
            )
          : animation,
      child: child,
    ),
    layoutBuilder: (currentChild, previousChildren) => Stack(
      alignment: alignment,
      children: [
        for (final previousChild in previousChildren)
          ExcludeSemantics(child: IgnorePointer(child: previousChild)),
        ?currentChild,
      ],
    ),
    child: child,
  );
}
