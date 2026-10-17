import 'dart:async';
import 'package:flutter/material.dart';
import 'app_tap_handler.dart';
import 'tap_config.dart';

/// Các tiện ích mở rộng (Extension) giúp gọi AppTapHandler cực kỳ ngắn gọn và tự nhiên.
extension AppTapContextExtension on BuildContext {
  /// Bọc hàm callback với hệ thống AppTapHandler trung tâm
  /// Sử dụng trực tiếp trong:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: context.onAppTap(
  ///     () => login(),
  ///     actionName: 'btn_login',
  ///     requiresNetwork: true,
  ///   ),
  ///   child: Text('Đăng nhập'),
  /// )
  /// ```
  VoidCallback? onAppTap(
    FutureOr<void> Function()? onTap, {
    String? actionName,
    bool requiresAuth = false,
    bool requiresNetwork = false,
    Duration throttleDuration = const Duration(milliseconds: 500),
    bool enableHaptic = true,
    Map<String, dynamic>? params,
    FutureOr<bool> Function(BuildContext context)? customGuard,
    TapConfig? config,
  }) {
    return AppTapHandler.wrap(
      this,
      onTap: onTap,
      actionName: actionName,
      requiresAuth: requiresAuth,
      requiresNetwork: requiresNetwork,
      throttleDuration: throttleDuration,
      enableHaptic: enableHaptic,
      params: params,
      customGuard: customGuard,
      config: config,
    );
  }
}

extension AppTapFunctionExtension on FutureOr<void> Function()? {
  /// Bọc một hàm Function thành onTap có qua xử lý trung tâm
  /// ```dart
  /// () => submit().withTap(context, actionName: 'submit_form')
  /// ```
  VoidCallback? withTap(
    BuildContext context, {
    String? actionName,
    bool requiresAuth = false,
    bool requiresNetwork = false,
    Duration throttleDuration = const Duration(milliseconds: 500),
    bool enableHaptic = true,
    Map<String, dynamic>? params,
    FutureOr<bool> Function(BuildContext context)? customGuard,
    TapConfig? config,
  }) {
    return AppTapHandler.wrap(
      context,
      onTap: this,
      actionName: actionName,
      requiresAuth: requiresAuth,
      requiresNetwork: requiresNetwork,
      throttleDuration: throttleDuration,
      enableHaptic: enableHaptic,
      params: params,
      customGuard: customGuard,
      config: config,
    );
  }
}
