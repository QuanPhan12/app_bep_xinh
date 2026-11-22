import 'package:flutter/material.dart';
import 'package:app_bep_xinh/sollume/core/theme/app_theme.dart';

enum AppSliverAppBarVariant { root, detail }

/// Thanh tiêu đề dùng trực tiếp trong [CustomScrollView.slivers].
///
/// Màn hình truyền nút back qua [leading], tiêu đề và các action; việc điều
/// hướng thuộc màn hình gọi. Với nút back có nhãn, truyền thêm [leadingWidth].
/// Đặt [primary] thành false nếu bên ngoài đã có SafeArea phía trên.
class AppSliverAppBar extends StatelessWidget {
  const AppSliverAppBar({
    super.key,
    required this.title,
    this.leading,
    this.leadingWidth,
    this.centerTitle = false,
    this.actions = const [],
    this.floating = false,
    this.pinned = true,
    this.primary = true,
    this.variant = AppSliverAppBarVariant.root,
    this.showDivider = false,
  }) : assert(
         leadingWidth == null ||
             (leadingWidth > 0 && leadingWidth < double.infinity),
       );

  const AppSliverAppBar.root({
    super.key,
    required this.title,
    this.leading,
    this.leadingWidth,
    this.actions = const [],
    this.primary = true,
    this.floating = true,
    this.pinned = false,
  }) : centerTitle = false,
       variant = AppSliverAppBarVariant.root,
       showDivider = false;

  const AppSliverAppBar.detail({
    super.key,
    required this.title,
    this.leading,
    this.leadingWidth,
    this.actions = const [],
    this.primary = true,
    this.floating = false,
    this.pinned = true,
  }) : centerTitle = true,
       variant = AppSliverAppBarVariant.detail,
       showDivider = true;

  final Widget title;
  final Widget? leading;
  final bool? centerTitle;
  final double? leadingWidth;
  final List<Widget> actions;
  final bool pinned;
  final bool? floating;
  final bool primary;
  final AppSliverAppBarVariant variant;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      primary: primary,
      pinned: pinned,
      // Không tự sinh nút back/drawer: màn hình quyết định các thao tác.
      automaticallyImplyLeading: false,
      leading: leading,
      leadingWidth: leadingWidth,
      title: DefaultTextStyle.merge(
        style:
            (variant == AppSliverAppBarVariant.root
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.titleMedium)
                ?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.appColors.text,
                ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: title,
      ),
      floating: floating ?? false,
      centerTitle: centerTitle,
      titleSpacing: AppSpacing.resolve(context, AppSpacing.sm),
      actions: actions,
      actionsPadding: EdgeInsetsDirectional.only(
        end: AppSpacing.resolve(context, AppSpacing.xs),
      ),
      // SliverAppBar mặc định dùng 56px; lấy chiều cao theme đã hỗ trợ cỡ chữ.
      toolbarHeight: theme.appBarTheme.toolbarHeight ?? kToolbarHeight,
      shape: showDivider
          ? Border(bottom: Divider.createBorderSide(context))
          : null,
    );
  }
}
