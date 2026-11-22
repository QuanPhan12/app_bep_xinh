import 'dart:async';

import '../../sollume/shared/app_sliver_app_bar.dart' as sollume;

import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import '../text_styles/app_text_styles.dart';
import 'app_bar_style.dart';

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

  /// Màu chữ tiêu đề và icon (Mặc định: trắng trên gradient, hoặc [context.colors.textPrimary] trên nền sáng)
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
  final FutureOr<void> Function()? onBackPressed;

  final bool backEnabled;

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
    this.backEnabled = true,
  });

  /// Tab gốc không có nút quay lại; thanh tiêu đề ẩn khi cuộn xuống
  /// và hiện ngay khi cuộn ngược để người dùng nhận biết màn đang mở.
  const AppSliverAppBar.tab({
    super.key,
    required this.title,
    this.actions,
    this.titleWidget,
  }) : leading = null,
       automaticallyImplyLeading = false,
       centerTitle = false,
       pinned = false,
       floating = true,
       snap = true,
       backgroundColor = null,
       gradient = null,
       foregroundColor = null,
       expandedHeight = null,
       flexibleSpace = null,
       bottom = null,
       scrolledUnderElevation = 0,
       onBackPressed = null,
       backEnabled = true;

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
        foregroundColor ?? (effectiveGradient != null ? Colors.white : null);

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
    final style = AppBarStyle(
      backgroundColor: backgroundColor ?? context.colors.surface,
      gradient: gradient,
      foregroundColor:
          foregroundColor ??
          (gradient == null ? context.colors.textPrimary : null),
    );
    final leadingWidget =
        leading ??
        (automaticallyImplyLeading &&
                (onBackPressed != null || appBarCanPop(context))
            ? AppBarBackButton(
                style: style,
                enabled: backEnabled,
                onBack: onBackPressed ?? () => appBarPop(context),
              )
            : null);

    if (expandedHeight == null &&
        flexibleSpace == null &&
        bottom == null &&
        !snap &&
        gradient == null) {
      return sollume.AppSliverAppBar(
        title: titleWidget ?? Text(title ?? ''),
        leading: leadingWidget,
        actions: actions ?? const [],
        centerTitle: centerTitle,
        pinned: pinned,
        floating: floating,
        showDivider: leadingWidget != null,
        variant: leadingWidget == null
            ? sollume.AppSliverAppBarVariant.root
            : sollume.AppSliverAppBarVariant.detail,
      );
    }
    return SliverAppBar(
      pinned: pinned,
      floating: floating,
      snap: snap,
      elevation: 0,
      scrolledUnderElevation: style.gradient != null
          ? 0
          : (scrolledUnderElevation ?? 0.5),
      backgroundColor: style.background,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      iconTheme: IconThemeData(color: style.foreground),
      actionsIconTheme: IconThemeData(color: style.foreground),
      title: titleWidget ?? (title != null ? style.title(title!) : null),
      actions: actions,
      expandedHeight: expandedHeight,
      flexibleSpace: style.flexibleSpace(flexibleSpace),
      bottom: bottom,
      systemOverlayStyle: style.overlay,
    );
  }
}
