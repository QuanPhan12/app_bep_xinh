import 'dart:async';

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/tap/app_tap_handler.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../models/home_banner_item.dart';
import 'home_banner_slide.dart';

/// Widget có state vì sở hữu controller, observer và notifier của UI.
class HomeBanner extends StatefulWidget {
  final FutureOr<void> Function(String)? onTap;
  final List<HomeBannerItem> banners;
  final bool isVisible;

  const HomeBanner({
    super.key,
    required this.banners,
    this.onTap,
    this.isVisible = true,
  });

  static double heightOf(BuildContext context) =>
      160.h(context) +
      (MediaQuery.textScalerOf(context).scale(18) - 18).clamp(0, 72) * 4;

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> with WidgetsBindingObserver {
  final _controller = CarouselSliderController();
  final _index = ValueNotifier<int>(0);
  final _pointers = <int>{};
  late AppLifecycleState? _lifecycle;
  int _sequence = 0;
  bool _autoplayEnabled = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = WidgetsBinding.instance.lifecycleState;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant HomeBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.banners.map((item) => item.id).toList();
    final ids = widget.banners.map((item) => item.id).toList();
    if (!listEquals(oldIds, ids)) {
      final activeId = oldIds.isEmpty
          ? null
          : oldIds[_index.value.clamp(0, oldIds.length - 1)];
      final next = ids.indexOf(activeId ?? '');
      _index.value = next < 0 ? 0 : next;
      // Chỉ tạo lại carousel khi chuỗi id đổi; refresh dữ liệu cùng id giữ trang.
      _sequence++;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || state == _lifecycle) return;
    setState(() {
      _lifecycle = state;
      _pointers.clear();
    });
    // paused có thể không vẽ thêm frame: phải dừng Timer ngay, không chỉ setState.
    if (state != AppLifecycleState.resumed) {
      if (_controller.ready) _controller.stopAutoPlay();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _lifecycle == AppLifecycleState.resumed &&
            _autoplayEnabled &&
            _controller.ready) {
          _controller.startAutoPlay();
        }
      });
    }
  }

  void _pointerDown(PointerDownEvent event) {
    final wasEmpty = _pointers.isEmpty;
    _pointers.add(event.pointer);
    if (wasEmpty) setState(() {});
  }

  void _pointerUp(PointerEvent event) {
    if (_pointers.remove(event.pointer) && _pointers.isEmpty) setState(() {});
  }

  Future<void> _goTo(int index) => AppTapHandler.handle(
    context,
    actionName: 'home_banner_page',
    onTap: () async {
      if (!mounted || !_controller.ready || index >= widget.banners.length) {
        return;
      }
      await _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    final canPlay =
        widget.banners.length > 1 &&
        widget.isVisible &&
        TickerMode.valuesOf(context).enabled &&
        _pointers.isEmpty &&
        (_lifecycle == null || _lifecycle == AppLifecycleState.resumed) &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    _autoplayEnabled = canPlay;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: Listener(
            onPointerDown: _pointerDown,
            onPointerUp: _pointerUp,
            onPointerCancel: _pointerUp,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CarouselSlider.builder(
                  key: ValueKey(_sequence),
                  carouselController: _controller,
                  itemCount: widget.banners.length,
                  itemBuilder: (context, index, _) => HomeBannerSlide(
                    banner: widget.banners[index],
                    onTap: widget.onTap == null
                        ? null
                        : () => widget.onTap!(widget.banners[index].id),
                  ),
                  options: CarouselOptions(
                    height: HomeBanner.heightOf(context),
                    viewportFraction: 1,
                    initialPage: _index.value,
                    enableInfiniteScroll: widget.banners.length > 1,
                    autoPlay: canPlay,
                    autoPlayInterval: const Duration(seconds: 4),
                    autoPlayAnimationDuration: const Duration(
                      milliseconds: 700,
                    ),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    onPageChanged: (index, _) {
                      if (mounted &&
                          index >= 0 &&
                          index < widget.banners.length) {
                        _index.value = index;
                      }
                    },
                  ),
                ),
                if (widget.banners.length > 1) ...[
                  SizedBox(height: 8.h(context)),
                  // Đổi trang chỉ rebuild indicator; ảnh/nội dung slide giữ identity.
                  ValueListenableBuilder<int>(
                    valueListenable: _index,
                    builder: (context, index, _) => AnimatedSmoothIndicator(
                      activeIndex: index,
                      count: widget.banners.length,
                      effect: ExpandingDotsEffect(
                        dotHeight: 4.h(context),
                        dotWidth: 5.w(context),
                        expansionFactor: 3.5,
                        activeDotColor: AppColors.primary,
                        dotColor: AppColors.border,
                        spacing: 4.w(context),
                      ),
                      onDotClicked: _goTo,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _index.dispose();
    super.dispose();
  }
}
