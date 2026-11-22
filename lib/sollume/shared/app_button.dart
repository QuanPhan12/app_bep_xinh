import 'package:app_bep_xinh/sollume/l10n/l10n.dart';
import 'package:app_bep_xinh/sollume/shared/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:app_bep_xinh/sollume/core/animation/app_animated_switcher.dart';
import 'package:app_bep_xinh/sollume/core/theme/app_responsive.dart';
import 'package:app_bep_xinh/sollume/shared/app_button_label.dart';

enum AppButtonVariant { primary, secondary }

/// Nút dùng chung, nhận trạng thái loading từ widget cha hoặc Cubit.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.style,
    this.statesController,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.style,
    this.statesController,
  }) : variant = AppButtonVariant.secondary;

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final ButtonStyle? style;
  final WidgetStatesController? statesController;

  @override
  Widget build(BuildContext context) {
    final indicatorSize = AppResponsive.of(context).size(20, min: 20, max: 24);
    final colors = Theme.of(context).colorScheme;
    final secondary = variant == AppButtonVariant.secondary;
    final background = secondary ? colors.surfaceContainer : colors.primary;
    final foreground = secondary ? colors.onSurface : colors.onPrimary;

    final roleStyle = secondary || isLoading
        ? FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: isLoading
                ? background
                : colors.surfaceContainer,
            disabledForegroundColor: isLoading
                ? foreground
                : colors.onSurfaceVariant.withValues(alpha: .6),
          )
        : null;
    return FilledButton(
      statesController: statesController,
      // styleFrom giữ cả property null của typography. Ưu tiên cấu hình caller
      // để chữ/geometry không đổi khi role chuyển primary ↔ secondary/loading.
      style: style?.merge(roleStyle) ?? roleStyle,
      onPressed: isLoading ? null : onPressed,
      // Đọc foreground đã resolve của FilledButton, kể cả disabled/loading.
      child: Builder(
        builder: (context) => AppAnimatedSwitcher(
          transition: AppSwitcherTransition.fadeThrough,
          child: Stack(
            key: ValueKey(isLoading),
            alignment: Alignment.center,
            children: [
              Visibility(
                visible: !isLoading,
                maintainState: true,
                maintainAnimation: true,
                maintainSize: true,
                child: icon == null ? AppButtonLabel(context.uiLabel(label)) : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(icon, size: 20), const SizedBox(width: 8),
                    Flexible(child: AppButtonLabel(context.uiLabel(label)))],
                ),
              ),
              SizedBox.square(
                dimension: indicatorSize,
                child: isLoading
                    ? AppLoadingIndicator(
                        key: const ValueKey('loading'),
                        color: DefaultTextStyle.of(context).style.color,
                        semanticsLabel: context.l10n.actionProcessing(
                          (label).toString(),
                        ),
                        size: indicatorSize,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
