import 'dart:async';

import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../dimensions/dimensions.dart';
import '../text_styles/app_text_styles.dart';
import '../tap/app_tap_handler.dart';
import '../tap/tap_config.dart';

enum AppButtonVariant { primary, secondary, outlined, ghost }

/// Nút bấm chuẩn hóa toàn app Bếp Xinh tích hợp sẵn hệ thống kiểm soát onTap tập trung
/// và tự động tính toán kích thước co giãn thích ứng theo từng dòng máy qua AppSize.
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
    final effectiveHeight = height ?? context.appSize.buttonHeight;
    final effectiveRadius = borderRadius ?? context.r(12);

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

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.primary
                    ? Colors.white
                    : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ] else ...[
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text, style: _getTextStyle(), maxLines: 1),
            ),
          ),
        ],

        // Dùng FittedBox để trên máy màn hình hẹp chữ tự động co lại thay vì rớt dòng đẩy phình nút
      ],
    );

    Widget buttonWidget;
    switch (variant) {
      case AppButtonVariant.primary:
        buttonWidget = Container(
          height: effectiveHeight,
          decoration: BoxDecoration(
            gradient: isDisabled ? null : AppColors.primaryGradient,
            color: isDisabled ? AppColors.borderDark : null,
            borderRadius: BorderRadius.circular(effectiveRadius),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: resolvedOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(effectiveRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: content,
          ),
        );
        break;

      case AppButtonVariant.secondary:
        buttonWidget = SizedBox(
          height: effectiveHeight,
          child: ElevatedButton(
            onPressed: resolvedOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: customColor ?? AppColors.primary50,
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(effectiveRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: content,
          ),
        );
        break;

      case AppButtonVariant.outlined:
        buttonWidget = SizedBox(
          height: effectiveHeight,
          child: OutlinedButton(
            onPressed: resolvedOnPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: customColor ?? AppColors.primary,
              side: BorderSide(
                color: isDisabled
                    ? AppColors.borderDark
                    : (customColor ?? AppColors.primary),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(effectiveRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: content,
          ),
        );
        break;

      case AppButtonVariant.ghost:
        buttonWidget = SizedBox(
          height: effectiveHeight,
          child: TextButton(
            onPressed: resolvedOnPressed,
            style: TextButton.styleFrom(
              foregroundColor: customColor ?? AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(effectiveRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: content,
          ),
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: buttonWidget);
    }
    return buttonWidget;
  }

  TextStyle _getTextStyle() {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppTextStyles.labelLarge.copyWith(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w600,
        );
      case AppButtonVariant.secondary:
      case AppButtonVariant.outlined:
      case AppButtonVariant.ghost:
        return AppTextStyles.labelLarge.copyWith(
          color: customColor ?? AppColors.primary,
          fontWeight: FontWeight.w600,
        );
    }
  }
}
