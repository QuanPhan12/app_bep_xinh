import 'dart:async';

import 'package:flutter/material.dart';

import '../tap/app_tap_handler.dart';
import '../tap/tap_config.dart';

/// Widget bọc bất kỳ phần tử nào (Card, Container, Icon, Image,...) để biến nó thành
/// một vùng bấm có kiểm soát tập trung qua `AppTapHandler`.
///
/// Hỗ trợ:
/// - Hiệu ứng nhấn mượt mà (scale down 0.97 nhẹ hoặc đổi opacity)
/// - Hoặc hiệu ứng sóng nước Material InkWell
/// - Chống spam click (Throttle)
/// - Rung nhẹ (Haptic feedback)
/// - Kiểm tra mạng (requiresNetwork)
/// - Kiểm tra đăng nhập (requiresAuth)
class AppTap extends StatefulWidget {
  final Widget child;
  final FutureOr<void> Function()? onTap;
  final FutureOr<void> Function()? onLongPress;
  final String? actionName;
  final bool requiresAuth;
  final bool requiresNetwork;
  final Duration throttleDuration;
  final bool enableHaptic;
  final Map<String, dynamic>? params;
  final FutureOr<bool> Function(BuildContext context)? customGuard;
  final TapConfig? config;
  final bool allowConcurrent;
  final bool allowMultiTap;
  final Duration? globalThrottleDuration;

  /// Hiệu ứng co nhẹ khi nhấn (micro-interaction scale)
  final bool scaleOnTap;

  /// Hiệu ứng mờ nhẹ khi nhấn
  final bool fadeOnTap;

  /// Sử dụng hiệu ứng sóng nước InkWell của Material thay cho GestureDetector
  final bool useRipple;

  /// Bán kính bo góc cho hiệu ứng InkWell
  final BorderRadius? borderRadius;

  const AppTap({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.actionName,
    this.requiresAuth = false,
    this.requiresNetwork = false,
    this.throttleDuration = const Duration(milliseconds: 100),
    this.enableHaptic = true,
    this.params,
    this.customGuard,
    this.config,
    this.allowConcurrent = false,
    this.allowMultiTap = false,
    this.globalThrottleDuration,
    this.scaleOnTap = true,
    this.fadeOnTap = true,
    this.useRipple = false,
    this.borderRadius,
  });

  @override
  State<AppTap> createState() => _AppTapState();
}

class _AppTapState extends State<AppTap> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 120),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) {
      _animController.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      _animController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _animController.reverse();
    }
  }

  void _handleTap() {
    AppTapHandler.handle(
      context,
      onTap: widget.onTap,
      config: widget.config,
      actionName: widget.actionName,
      requiresAuth: widget.requiresAuth,
      requiresNetwork: widget.requiresNetwork,
      throttleDuration: widget.throttleDuration,
      enableHaptic: widget.enableHaptic,
      params: widget.params,
      customGuard: widget.customGuard,
      allowConcurrent: widget.allowConcurrent,
      allowMultiTap: widget.allowMultiTap,
      globalThrottleDuration: widget.globalThrottleDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    if (widget.useRipple) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          onLongPress: widget.onLongPress != null
              ? () => AppTapHandler.handle(
                  context,
                  onTap: widget.onLongPress,
                  actionName: '${widget.actionName ?? 'item'}_long_press',
                  enableHaptic: widget.enableHaptic,
                )
              : null,
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _handleTap,
      onLongPress: widget.onLongPress != null
          ? () => AppTapHandler.handle(
              context,
              onTap: widget.onLongPress,
              actionName: '${widget.actionName ?? 'item'}_long_press',
              enableHaptic: widget.enableHaptic,
            )
          : null,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          Widget current = child!;
          if (widget.fadeOnTap) {
            current = Opacity(opacity: _fadeAnimation.value, child: current);
          }
          if (widget.scaleOnTap) {
            current = Transform.scale(
              scale: _scaleAnimation.value,
              child: current,
            );
          }
          return current;
        },
        child: widget.child,
      ),
    );
  }
}
