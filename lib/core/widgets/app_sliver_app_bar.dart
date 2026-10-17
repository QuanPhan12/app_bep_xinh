import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../colors/app_colors.dart';
import '../text_styles/app_text_styles.dart';
import 'app_tap.dart';

/// SliverAppBar chuẩn hóa dùng chung cho toàn bộ ứng dụng Bếp Xinh trong [CustomScrollView].
///
/// Các tính năng nổi bật:
/// - Mặc định nền là [AppColors.primaryGradient] theo chuẩn thương hiệu Bếp Xinh.
/// - Tự động tích hợp nút Back Button có hiệu ứng tap mượt `AppTap` và `context.pop()`.
/// - Hỗ trợ cả 2 dạng: Standard và Large Collapsing Title (`AppSliverAppBar.large`).
/// - Tự động đồng bộ màu chữ / icon (trắng khi dùng gradient) và màu status bar.
/// - Hỗ trợ đầy đủ các cơ chế cuộn: `pinned`, `floating`, `snap`, `expandedHeight`, `actions`, `bottom`.
class AppSliverAppBar extends StatelessWidget {
  /// Tiêu đề dạng chuỗi chữ (hiển thị font Be Vietnam Pro chuẩn)
  final String? title;

  /// Hoặc Widget tiêu đề tùy biến hoàn toàn
  final Widget? titleWidget;

  /// Nút góc trái (Mặc định tự hiện nút Back nếu Navigator có thể pop)
  final Widget? leading;

  /// Tự động hiện nút back khi có thể pop
  final bool automaticallyImplyLeading;

  /// Danh sách nút thao tác góc phải
  final List<Widget>? actions;

  /// Căn giữa tiêu đề (Mặc định: true)
  final bool centerTitle;

  /// Giữ cố định AppBar trên đỉnh khi cuộn (Mặc định: true)
  final bool pinned;

  /// Hiện lại AppBar ngay khi vừa cuộn ngược lên (Mặc định: false)
  final bool floating;

  /// Tự động bật mở hết cỡ khi thả tay (Mặc định: false)
  final bool snap;

  /// Màu nền phẳng (Nếu để null, AppBar sẽ tự động dùng [gradient] hoặc [AppColors.primaryGradient])
  final Color? backgroundColor;

  /// Gradient nền AppBar (Mặc định: [AppColors.primaryGradient] khi [backgroundColor] == null)
  final Gradient? gradient;

  /// Màu chữ tiêu đề và icon (Mặc định: trắng trên gradient, hoặc [AppColors.textPrimary] trên nền sáng)
  final Color? foregroundColor;

  /// Chiều cao mở rộng (dành cho màn hình có ảnh bìa / banner lớn)
  final double? expandedHeight;

  /// Vùng co giãn linh hoạt (FlexibleSpaceBar)
  final Widget? flexibleSpace;

  /// Thanh gắn dưới đáy AppBar (ví dụ: TabBar, SearchBar)
  final PreferredSizeWidget? bottom;

  /// Độ đổ bóng khi cuộn nội dung bên dưới
  final double? scrolledUnderElevation;

  /// Callback tùy biến khi ấn nút quay lại
  final VoidCallback? onBackPressed;

  const AppSliverAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.centerTitle = true,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.backgroundColor,
    this.gradient,
    this.foregroundColor,
    this.expandedHeight,
    this.flexibleSpace,
    this.bottom,
    this.scrolledUnderElevation,
    this.onBackPressed,
  });

  /// Factory tạo SliverAppBar dạng Large Title co giãn mượt mà khi cuộn
  factory AppSliverAppBar.large({
    Key? key,
    required String title,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    List<Widget>? actions,
    Color? backgroundColor,
    Gradient? gradient,
    Color? foregroundColor,
    double expandedHeight = 110.0,
    Widget? background,
    PreferredSizeWidget? bottom,
    VoidCallback? onBackPressed,
  }) {
    final bool hasExplicitBg = backgroundColor != null;
    final effectiveGradient = hasExplicitBg
        ? gradient
        : (gradient ?? AppColors.primaryGradient);
    final effectiveForeground =
        foregroundColor ??
        (effectiveGradient != null ? Colors.white : AppColors.textPrimary);

    return AppSliverAppBar(
      key: key,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      centerTitle: false,
      pinned: true,
      floating: false,
      snap: false,
      backgroundColor: backgroundColor,
      gradient: gradient,
      foregroundColor: effectiveForeground,
      expandedHeight: expandedHeight,
      bottom: bottom,
      onBackPressed: onBackPressed,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
        title: Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: effectiveForeground,
          ),
        ),
        background: background,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop =
        context.canPop() || (ModalRoute.of(context)?.canPop ?? false);

    // Xác định gradient hoặc màu nền
    final bool hasExplicitBg = backgroundColor != null;
    final Gradient? effectiveGradient = hasExplicitBg
        ? gradient
        : (gradient ?? AppColors.primaryGradient);

    final Color effectiveForeground =
        foregroundColor ??
        (effectiveGradient != null ? Colors.white : AppColors.textPrimary);

    final Color effectiveBg = effectiveGradient != null
        ? Colors.transparent
        : (backgroundColor ?? AppColors.surface);

    // Xử lý nút Back chuẩn UI/UX
    Widget? leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading && canPop) {
      leadingWidget = AppTap(
        actionName: 'app_bar_back',
        onTap: () {
          if (onBackPressed != null) {
            onBackPressed!();
          } else if (context.canPop()) {
            context.pop();
          } else {
            Navigator.of(context).maybePop();
          }
        },
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: effectiveGradient != null
                  ? Colors.white.withValues(alpha: 0.2)
                  : (effectiveBg == Colors.transparent
                        ? Colors.black.withValues(alpha: 0.25)
                        : Colors.transparent),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: effectiveForeground,
              size: 18,
            ),
          ),
        ),
      );
    }

    // Tích hợp gradient vào flexibleSpace
    Widget? effectiveFlexibleSpace = flexibleSpace;
    if (effectiveGradient != null) {
      if (effectiveFlexibleSpace == null) {
        effectiveFlexibleSpace = Container(
          decoration: BoxDecoration(gradient: effectiveGradient),
        );
      } else {
        effectiveFlexibleSpace = Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: BoxDecoration(gradient: effectiveGradient)),
            effectiveFlexibleSpace,
          ],
        );
      }
    }

    // Xác định style cho StatusBar
    final SystemUiOverlayStyle overlayStyle = effectiveGradient != null
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          )
        : (ThemeData.estimateBrightnessForColor(effectiveBg) == Brightness.dark
              ? SystemUiOverlayStyle.light.copyWith(
                  statusBarColor: Colors.transparent,
                )
              : SystemUiOverlayStyle.dark.copyWith(
                  statusBarColor: Colors.transparent,
                ));

    return SliverAppBar(
      pinned: pinned,
      floating: floating,
      snap: snap,
      elevation: 0,
      scrolledUnderElevation: effectiveGradient != null
          ? 0
          : (scrolledUnderElevation ?? 0.5),
      backgroundColor: effectiveBg,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      iconTheme: IconThemeData(color: effectiveForeground),
      actionsIconTheme: IconThemeData(color: effectiveForeground),
      title:
          titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: effectiveForeground,
                  ),
                )
              : null),
      actions: actions,
      expandedHeight: expandedHeight,
      flexibleSpace: effectiveFlexibleSpace,
      bottom: bottom,
      systemOverlayStyle: overlayStyle,
    );
  }
}
