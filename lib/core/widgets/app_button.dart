import 'dart:async';

import 'package:flutter/material.dart';

import '../../sollume/shared/app_button.dart' as sollume;

import '../tap/app_tap_handler.dart';
import '../tap/tap_config.dart';

enum AppButtonVariant { primary, secondary, ghost }

/// Adapter giữ guard của Bếp Xinh và giao diện/loading từ AppButton Sollume.
class AppButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final FutureOr<void> Function()? onPressed;
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

  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;

  /// Nếu null, sẽ tự động dùng chiều cao thích ứng từ AppSize (46 cho máy nhỏ, 50 máy chuẩn, 58 tablet)
  final double? height;

  /// Nếu null, sẽ tự động dùng bo góc thích ứng từ AppSize
  final double? borderRadius;
  final Color? customColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
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
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height,
    this.borderRadius,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final resolvedOnPressed = isDisabled
        ? null
        : AppTapHandler.wrap(
            context,
            onTap: onPressed,
            actionName:
                actionName ?? 'btn_${text.toLowerCase().replaceAll(' ', '_')}',
            requiresAuth: requiresAuth,
            requiresNetwork: requiresNetwork,
            throttleDuration: throttleDuration,
            enableHaptic: enableHaptic,
            params: params,
            customGuard: customGuard,
            allowConcurrent: allowConcurrent,
            allowMultiTap: allowMultiTap,
            globalThrottleDuration: globalThrottleDuration,
            config: config,
          );

    final style = FilledButton.styleFrom(
      minimumSize: height == null ? null : Size(0, height!),
      backgroundColor: customColor,
      shape: borderRadius == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius!),
            ),
    );
    final content = variant == AppButtonVariant.ghost
        ? icon == null
              ? TextButton(onPressed: resolvedOnPressed, child: Text(text))
              : TextButton.icon(
                  onPressed: resolvedOnPressed,
                  icon: Icon(icon, size: 20),
                  label: Text(text),
                )
        : sollume.AppButton(
            label: text,
            icon: icon,
            onPressed: resolvedOnPressed,
            isLoading: isLoading,
            variant: variant == AppButtonVariant.primary
                ? sollume.AppButtonVariant.primary
                : sollume.AppButtonVariant.secondary,
            style: style,
          );
    return isFullWidth
        ? SizedBox(width: double.infinity, child: content)
        : content;
  }
}
