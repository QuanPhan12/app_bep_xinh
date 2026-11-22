import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:app_bep_xinh/sollume/core/animation/app_motion.dart';
import 'package:app_bep_xinh/sollume/core/theme/app_radius.dart';

typedef AppTapBuilder = Widget Function(
  BuildContext context,
  WidgetStatesController statesController,
);

/// Thu nhỏ nội dung khi nhấn; hành động và guard thuộc Cubit của màn hình.
class AppTap extends StatefulWidget {
  const AppTap({
    super.key,
    required Widget this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.borderRadius,
  }) : builder = null;

  /// Bọc control Material; truyền controller cho control để dùng chung trạng thái
  /// pressed từ chuột, cảm ứng và bàn phím, không thêm vùng nhận gesture thứ hai.
  const AppTap.builder({
    super.key,
    required AppTapBuilder this.builder,
    this.enabled = true,
  }) : child = null,
       onTap = null,
       onLongPress = null,
       borderRadius = null;

  final Widget? child;
  final AppTapBuilder? builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final BorderRadius? borderRadius;

  @override
  State<AppTap> createState() => _AppTapState();
}

class _AppTapState extends State<AppTap> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  final _statesController = WidgetStatesController();
  bool _reduceMotion = false;
  bool _updateScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.press,
      reverseDuration: AppMotion.fast,
    );
    _scale = _controller
        .drive(CurveTween(curve: AppMotion.enterCurve))
        .drive(Tween<double>(begin: 1, end: AppMotion.pressedScale));
    _statesController.addListener(_statesChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = AppMotion.reduceMotion(context);
    _updatePressed();
  }

  @override
  void didUpdateWidget(covariant AppTap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePressed();
  }

  void _statesChanged() {
    // InkWell có thể đổi trạng thái khi build (ví dụ vừa bị disable).
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_updateScheduled) return;
      _updateScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScheduled = false;
        if (mounted) _updatePressed();
      });
      return;
    }
    _updatePressed();
  }

  void _updatePressed() {
    final states = _statesController.value;
    final interactive =
        widget.enabled &&
        (widget.builder != null ||
            widget.onTap != null ||
            widget.onLongPress != null);
    if (_reduceMotion ||
        !interactive ||
        states.contains(WidgetState.disabled)) {
      if (_controller.value != 0 || _controller.isAnimating) {
        _controller.reset();
      }
    } else if (states.contains(WidgetState.pressed)) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _statesController.removeListener(_statesChanged);
    _statesController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child =
        widget.builder?.call(context, _statesController) ??
        InkWell(
          statesController: _statesController,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          onTap: widget.enabled ? widget.onTap : null,
          onLongPress: widget.enabled ? widget.onLongPress : null,
          borderRadius:
              widget.borderRadius ?? BorderRadius.circular(AppRadius.small),
          child: widget.child,
        );
    return ScaleTransition(scale: _scale, child: child);
  }
}
