import 'package:flutter/widgets.dart';

/// Thời gian và đường cong dùng chung cho chuyển động trong ứng dụng.
abstract final class AppMotion {
  static const press = Duration(milliseconds: 100);
  static const pressedScale = 0.97;
  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 240);
  static const page = Duration(milliseconds: 300);
  static const staggerStep = Duration(milliseconds: 40);

  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve resizeCurve = Curves.easeInOutCubic;

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration durationOf(BuildContext context, Duration duration) =>
      reduceMotion(context) ? Duration.zero : duration;

  /// Giới hạn độ trễ để danh sách dài không bắt người dùng chờ.
  static Duration stagger(int index) {
    assert(index >= 0);
    return staggerStep * index.clamp(0, 4);
  }
}
