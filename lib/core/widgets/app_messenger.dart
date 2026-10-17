import 'dart:async';
import 'package:flutter/material.dart';
import '../colors/app_colors.dart';
import '../text_styles/app_text_styles.dart';
import '../utils/responsive_utils.dart';

/// Các loại thông báo trong hệ thống Messenger
enum AppNotificationType {
  success,
  error,
  warning,
  info,
}

/// Hệ thống thông báo tùy biến (Custom Messenger) thay thế ScaffoldMessenger chuẩn.
/// Hỗ trợ 2 chế độ hiển thị thích ứng theo thiết bị (Responsive):
/// 1. Mobile (< 600px): Hiển thị ở DƯỚI (Bottom Floating Notification).
/// 2. Tablet (>= 600px): Hiển thị ở TRÊN GÓC TRÁI (Top-Left Floating Toast).
class AppMessenger {
  AppMessenger._();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Đóng thông báo đang hiển thị
  static void hide() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  /// Hiển thị thông báo dạng Success
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Hiển thị thông báo dạng Error
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Hiển thị thông báo dạng Warning
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Hiển thị thông báo dạng Info
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Hàm cốt lõi hiển thị thông báo với vị trí responsive
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Ẩn thông báo cũ nếu đang có
    hide();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final isTabletDevice = ResponsiveUtils.isTablet(context);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _AppNotificationWidget(
        message: message,
        title: title,
        type: type,
        isTablet: isTabletDevice,
        actionLabel: actionLabel,
        onAction: onAction,
        onClose: hide,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    // Tự động ẩn sau thời gian quy định
    _dismissTimer = Timer(duration, () {
      hide();
    });
  }
}

/// Widget hiển thị nội dung thông báo với hiệu ứng chuyển động và vị trí responsive
class _AppNotificationWidget extends StatefulWidget {
  final String message;
  final String? title;
  final AppNotificationType type;
  final bool isTablet;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onClose;

  const _AppNotificationWidget({
    required this.message,
    required this.type,
    required this.isTablet,
    required this.onClose,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_AppNotificationWidget> createState() => _AppNotificationWidgetState();
}

class _AppNotificationWidgetState extends State<_AppNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    // Tablet: Trượt nhẹ từ trên / góc trái sang phải
    // Mobile: Trượt nhẹ từ dưới lên trên
    final beginOffset = widget.isTablet
        ? const Offset(-0.25, 0.0)
        : const Offset(0.0, 0.4);

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // Màu sắc & Icon đại diện theo từng loại
    final Color mainColor;
    final Color bgColor;
    final IconData iconData;
    final String defaultTitle;

    switch (widget.type) {
      case AppNotificationType.success:
        mainColor = AppColors.success;
        bgColor = AppColors.successBg;
        iconData = Icons.check_circle_rounded;
        defaultTitle = 'Thành công';
        break;
      case AppNotificationType.error:
        mainColor = AppColors.error;
        bgColor = AppColors.errorBg;
        iconData = Icons.cancel_rounded;
        defaultTitle = 'Đã có lỗi xảy ra';
        break;
      case AppNotificationType.warning:
        mainColor = AppColors.warning;
        bgColor = AppColors.warningBg;
        iconData = Icons.warning_rounded;
        defaultTitle = 'Cảnh báo';
        break;
      case AppNotificationType.info:
        mainColor = AppColors.info;
        bgColor = AppColors.infoBg;
        iconData = Icons.info_rounded;
        defaultTitle = 'Thông báo';
        break;
    }

    final cardContent = Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: widget.isTablet ? 400 : double.infinity,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: mainColor.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: mainColor.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon biểu trưng với container nền nhạt
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: mainColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Tiêu đề & nội dung thông báo
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ?? defaultTitle,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Nút hành động bổ sung (nếu có)
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  _dismiss();
                  widget.onAction?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: mainColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  widget.actionLabel!,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: mainColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            // Nút đóng 'X'
            const SizedBox(width: 4),
            InkWell(
              onTap: _dismiss,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Kéo để vuốt tắt (Dismissible)
    final dismissibleCard = Dismissible(
      key: UniqueKey(),
      direction: widget.isTablet
          ? DismissDirection.horizontal
          : DismissDirection.down,
      onDismissed: (_) => widget.onClose(),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: cardContent,
        ),
      ),
    );

    // ==========================================
    // 2 CHẾ ĐỘ HIỂN THỊ RESPONSIVE:
    // - Tablet: Đặt ở TRÊN GÓC TRÁI (Top-Left)
    // - Mobile: Đặt ở DƯỚI (Bottom)
    // ==========================================
    if (widget.isTablet) {
      return Positioned(
        top: mediaQuery.padding.top + 20,
        left: 24,
        child: dismissibleCard,
      );
    } else {
      return Positioned(
        bottom: mediaQuery.padding.bottom + 20,
        left: 16,
        right: 16,
        child: dismissibleCard,
      );
    }
  }
}

/// Extension tiện lợi trên BuildContext để gọi AppMessenger mọi lúc mọi nơi
extension AppMessengerContextExtension on BuildContext {
  void showSuccess(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    AppMessenger.showSuccess(
      this,
      message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void showError(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    AppMessenger.showError(
      this,
      message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void showWarning(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    AppMessenger.showWarning(
      this,
      message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void showInfo(
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    AppMessenger.showInfo(
      this,
      message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void hideNotification() {
    AppMessenger.hide();
  }
}
