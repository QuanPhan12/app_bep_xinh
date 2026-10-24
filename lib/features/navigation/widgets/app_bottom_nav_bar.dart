import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/tap/app_tap_handler.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// StyleHook tùy biến sâu typography, kích thước icon cho ConvexAppBar
class _BepXinhStyleHook extends StyleHook {
  final BuildContext context;
  final bool showLabels;

  _BepXinhStyleHook(this.context, {this.showLabels = false});

  @override
  double get activeIconSize => 26.sp(context);

  @override
  double get activeIconMargin => 10.h(context);

  @override
  double get iconSize => showLabels ? 20.sp(context) : 24.sp(context);

  @override
  TextStyle textStyle(Color color, String? fontFamily) {
    return AppTextStyles.labelSmall.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
      fontSize: 10.sp(context),
      letterSpacing: -0.2,
    );
  }

  @override
  bool get hideEmptyLabel => true;
}

/// Thanh điều hướng đáy hiện đại với nút Đăng món (+) nổi bật ở chính giữa
/// - [showLabels]: Mặc định là `false` để ẩn chữ, tạo phong cách Icon-only tinh tế, tối giản và thoáng đãng.
/// - Khi [showLabels] = `true`, font chữ thương hiệu Be Vietnam Pro được áp dụng chuẩn chỉnh.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onAddTap;
  final bool showLabels;

  const AppBottomNavBar({
    super.key,
    this.currentIndex = 0,
    required this.onTabSelected,
    this.onAddTap,
    this.showLabels = false,
  });

  /// Chuyển đổi từ branchIndex (0..3) sang convexIndex (0..4)
  int get _convexIndex {
    if (currentIndex < 2) return currentIndex;
    return currentIndex + 1;
  }

  void _handleTap(BuildContext context, int index) {
    if (index == 2) {
      // Nhấn vào nút tròn nổi trung tâm "Đăng món"
      AppTapHandler.handle(
        context,
        actionName: 'nav_btn_add_recipe',
        onTap: onAddTap ?? () {},
      );
      return;
    }

    // Chuyển đổi từ convexIndex sang branchIndex trong GoRouter
    final branchIndex = index < 2 ? index : index - 1;
    AppTapHandler.handle(
      context,
      actionName: 'nav_tab_$branchIndex',
      onTap: () => onTabSelected(branchIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StyleProvider(
      style: _BepXinhStyleHook(context, showLabels: showLabels),
      child: ConvexAppBar(
        key: ValueKey('${_convexIndex}_$showLabels'),
        style: TabStyle.fixedCircle,
        backgroundColor: AppColors.surface,
        activeColor: AppColors.primary,
        color: AppColors.textTertiary,
        initialActiveIndex: _convexIndex,
        height: showLabels ? 54.h(context) : 50.h(context),
        curveSize: 76.w(context),
        top: -20.h(context),
        cornerRadius: 20.r(context),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        items: [
          TabItem(
            icon: CupertinoIcons.house,
            activeIcon: CupertinoIcons.house_fill,
            title: showLabels ? 'Trang chủ' : '',
          ),
          TabItem(
            icon: Icons.kitchen_outlined,
            activeIcon: Icons.kitchen_rounded,
            title: showLabels ? 'Tủ lạnh' : '',
          ),
          const TabItem(
            icon: Icons.add_rounded,
            title: '',
          ),
          TabItem(
            icon: CupertinoIcons.cart,
            activeIcon: CupertinoIcons.cart_fill,
            title: showLabels ? 'Đi chợ' : '',
          ),
          TabItem(
            icon: CupertinoIcons.person,
            activeIcon: CupertinoIcons.person_fill,
            title: showLabels ? 'Cá nhân' : '',
          ),
        ],
        onTap: (index) => _handleTap(context, index),
      ),
    );
  }
}
