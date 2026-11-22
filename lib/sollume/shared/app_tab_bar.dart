import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:app_bep_xinh/sollume/core/animation/app_motion.dart';
import 'package:app_bep_xinh/sollume/core/theme/app_theme.dart';

/// Thanh tab dùng chung; nhận controller bên ngoài hoặc DefaultTabController.
/// Màu, kiểu chữ và gạch chân lấy từ TabBarTheme được cấu hình trong AppTheme.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.onTap,
    this.isScrollable = true,
    this.spacing = AppSpacing.xxxl,
  }) : assert(spacing >= 0);

  final List<String> tabs;
  final TabController? controller;
  final ValueChanged<int>? onTap;
  final bool isScrollable;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabTheme = TabBarTheme.of(context);
    final tabController = controller ?? DefaultTabController.of(context);
    assert(tabController.length == tabs.length);
    final labelStyle = tabTheme.labelStyle ?? theme.textTheme.labelLarge!;
    final unselectedStyle = tabTheme.unselectedLabelStyle ?? labelStyle;
    final selectedColor = tabTheme.labelColor ?? theme.colorScheme.onSurface;
    final unselectedColor =
        tabTheme.unselectedLabelColor ?? theme.colorScheme.onSurfaceVariant;
    final metrics = AppResponsive.of(context);
    final verticalPadding = AppSpacing.resolve(context, AppSpacing.sm);
    // Tăng chiều cao theo chữ để không cắt dấu tiếng Việt.
    final height = math.max(
      metrics.control(AppSizes.minTouchTarget),
      MediaQuery.textScalerOf(context).scale(
                math.max(
                  labelStyle.fontSize ?? 14,
                  unselectedStyle.fontSize ?? 14,
                ),
              ) *
              math.max(
                labelStyle.height ?? 1.4,
                unselectedStyle.height ?? 1.4,
              ) +
          verticalPadding * 2,
    );
    final indicator =
        tabTheme.indicator ??
        UnderlineTabIndicator(
          borderSide: BorderSide(color: selectedColor, width: 2),
        );

    Widget buildTab(int index) {
      final progress =
          (1 -
                  ((tabController.animation?.value ??
                              tabController.index.toDouble()) -
                          index)
                      .abs())
              .clamp(0.0, 1.0);
      return _AppTabButton(
        label: tabs[index],
        selected: tabController.index == index,
        positionLabel: MaterialLocalizations.of(context)
            .tabLabel(tabIndex: index + 1, tabCount: tabs.length),
        height: height,
        scrollable: isScrollable,
        indicator: indicator,
        indicatorOpacity: progress,
        style: TextStyle.lerp(unselectedStyle, labelStyle, progress)!.copyWith(
          color: Color.lerp(unselectedColor, selectedColor, progress),
        ),
        onTap: () {
          tabController.animateTo(
            index,
            duration: AppMotion.durationOf(
              context,
              tabController.animationDuration,
            ),
          );
          onTap?.call(index);
        },
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([tabController, tabController.animation]),
      builder: (context, _) {
        final row = Semantics(
          role: SemanticsRole.tabBar,
          container: true,
          explicitChildNodes: true,
          child: Row(
            mainAxisSize: isScrollable ? MainAxisSize.min : MainAxisSize.max,
            // Khoảng cách thuộc layout, nằm ngoài vùng nhấn và overlay của mỗi tab.
            spacing: AppSpacing.resolve(context, spacing),
            children: [
              for (var index = 0; index < tabs.length; index++)
                if (isScrollable)
                  buildTab(index)
                else
                  Expanded(child: buildTab(index)),
            ],
          ),
        );
        return Material(
          type: MaterialType.transparency,
          child: isScrollable
              ? Align(
                  alignment: AlignmentDirectional.centerStart,
                  heightFactor: 1,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(overscroll: false),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: row,
                    ),
                  ),
                )
              : row,
        );
      },
    );
  }
}

class _AppTabButton extends StatefulWidget {
  const _AppTabButton({
    required this.label,
    required this.selected,
    required this.positionLabel,
    required this.height,
    required this.scrollable,
    required this.indicator,
    required this.indicatorOpacity,
    required this.style,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final String positionLabel;
  final double height;
  final bool scrollable;
  final Decoration indicator;
  final double indicatorOpacity;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  State<_AppTabButton> createState() => _AppTabButtonState();
}

class _AppTabButtonState extends State<_AppTabButton> {
  @override
  void initState() {
    super.initState();
    if (widget.selected) _reveal();
  }

  @override
  void didUpdateWidget(_AppTabButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) _reveal();
  }

  void _reveal() {
    if (!widget.scrollable) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = context.findRenderObject();
      final scrollable = Scrollable.maybeOf(context);
      if (target == null || scrollable == null) return;
      // Chỉ cuộn hàng tab, không làm dịch chuyển viewport của trang bên ngoài.
      scrollable.position.ensureVisible(
        target,
        duration: AppMotion.durationOf(context, AppMotion.fast),
        alignment: 0.5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabTheme = TabBarTheme.of(context);
    return MergeSemantics(
      child: Semantics(
        role: SemanticsRole.tab,
        selected: widget.selected,
        label: widget.positionLabel,
        child: InkWell(
          onTap: widget.onTap,
          overlayColor: tabTheme.overlayColor,
          splashFactory: tabTheme.splashFactory,
          borderRadius: BorderRadius.circular(AppRadius.small),
          onFocusChange: (focused) {
            if (focused) _reveal();
          },
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Stack(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: AppSizes.minTouchTarget,
                  ),
                  child: SizedBox(
                    height: widget.height,
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        widget.label,
                        style: widget.style,
                        textAlign: TextAlign.center,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: widget.indicatorOpacity,
                      child: DecoratedBox(decoration: widget.indicator),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
