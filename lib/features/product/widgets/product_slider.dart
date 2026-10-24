import 'dart:async';
import 'dart:math' as math;

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/tap/app_tap_handler.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/utils/responsive_utils.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:app_bep_xinh/features/product/widgets/product_card.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Slider hiển thị danh sách sản phẩm / công thức món ăn chuyên dụng
/// Tối ưu hóa đặc biệt cho giao diện Tablet và Mobile với thư viện tiêu chuẩn:
/// `carousel_slider: ^5.1.2` (Lazy loading on-demand) + `smooth_page_indicator: ^3.0.0`
class ProductSlider extends StatefulWidget {
  final String title;
  final List<RecipeItem> recipes;
  final ValueChanged<RecipeItem>? onRecipeTap;
  final FutureOr<void> Function(String)? onFavoriteTap;
  final VoidCallback? onViewAll;
  final bool autoPlay;

  const ProductSlider({
    super.key,
    this.title = 'Món ăn thịnh hành',
    required this.recipes,
    this.onRecipeTap,
    this.onFavoriteTap,
    this.onViewAll,
    this.autoPlay = false,
  });

  @override
  State<ProductSlider> createState() => _ProductSliderState();
}

class _ProductSliderState extends State<ProductSlider> {
  int _currentIndex = 0;
  int _sequence = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  Future<void> _goToPrevious() => _carouselController.previousPage(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
  );

  Future<void> _goToNext() => _carouselController.nextPage(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutCubic,
  );

  @override
  void didUpdateWidget(covariant ProductSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(
      oldWidget.recipes.map((item) => item.id).toList(),
      widget.recipes.map((item) => item.id).toList(),
    )) {
      _currentIndex = 0;
      _sequence++;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recipes.isEmpty) {
      return const SizedBox.shrink();
    }

    final isTablet = context.isTablet;
    // Trên Tablet hiển thị nhiều thẻ cùng lúc (~2.7 thẻ) để vuốt mượt mà
    final viewportFraction = isTablet ? 0.36 : 0.68;
    final baseHeight = isTablet ? 230.h(context) : 210.h(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = math.max(
          1.0,
          constraints.maxWidth * viewportFraction - 14.w(context),
        );
        final sliderHeight = math.max(
          baseHeight,
          ProductCard.minimumHeight(context, cardWidth),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh tiêu đề + Bộ điều hướng Prev/Next dành riêng cho Tablet
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp(context),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onViewAll != null) ...[
                        AppTap(
                          actionName: 'product_slider_view_all',
                          onTap: widget.onViewAll!,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w(context),
                              vertical: 4.h(context),
                            ),
                            child: Text(
                              'Xem tất cả',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp(context),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w(context)),
                      ],

                      // Nút chuyển trang Trái / Phải chuyên dụng trên Tablet
                      if (isTablet) ...[
                        _SliderNavButton(
                          icon: CupertinoIcons.chevron_left,
                          actionName: 'slider_btn_prev',
                          enabled: _currentIndex > 0,
                          onTap: _goToPrevious,
                        ),
                        SizedBox(width: 6.w(context)),
                        _SliderNavButton(
                          icon: CupertinoIcons.chevron_right,
                          actionName: 'slider_btn_next',
                          enabled: _currentIndex < widget.recipes.length - 1,
                          onTap: _goToNext,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h(context)),

            // Vùng Carousel Slider chuyên dụng chuẩn Production
            SizedBox(
              height: sliderHeight,
              child: CarouselSlider.builder(
                key: ValueKey(_sequence),
                carouselController: _carouselController,
                itemCount: widget.recipes.length,
                itemBuilder: (context, index, realIndex) {
                  final recipe = widget.recipes[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 16.w(context) : 4.w(context),
                      right: index == widget.recipes.length - 1
                          ? 16.w(context)
                          : 10.w(context),
                    ),
                    child: ProductCard(
                      recipe: recipe,
                      onTap: () => widget.onRecipeTap?.call(recipe),
                      onFavoriteTap: () =>
                          widget.onFavoriteTap?.call(recipe.id),
                    ),
                  );
                },
                options: CarouselOptions(
                  height: sliderHeight,
                  viewportFraction: viewportFraction,
                  initialPage: 0,
                  enableInfiniteScroll: false,
                  padEnds: false,
                  autoPlay: widget.autoPlay,
                  autoPlayInterval: const Duration(seconds: 4),
                  autoPlayAnimationDuration: const Duration(milliseconds: 600),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
              ),
            ),

            SizedBox(height: 12.h(context)),

            // Chỉ báo Dots Indicator chuyển động mượt mà (Smooth Page Indicator)
            Center(
              child: AnimatedSmoothIndicator(
                activeIndex: _currentIndex,
                count: widget.recipes.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 5.h(context),
                  dotWidth: 6.w(context),
                  expansionFactor: 3.2,
                  activeDotColor: AppColors.primary,
                  dotColor: AppColors.border,
                  spacing: 5.w(context),
                ),
                onDotClicked: (index) {
                  AppTapHandler.handle(
                    context,
                    actionName: 'product_slider_indicator_tap',
                    params: {'target_index': index},
                    onTap: () => _carouselController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Nút bấm điều hướng mũi tên dành riêng cho trải nghiệm Tablet
class _SliderNavButton extends StatelessWidget {
  final IconData icon;
  final String actionName;
  final bool enabled;
  final FutureOr<void> Function() onTap;

  const _SliderNavButton({
    required this.icon,
    required this.actionName,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTap(
      actionName: actionName,
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          width: 28.w(context),
          height: 28.h(context),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8.r(context)),
            border: Border.all(color: AppColors.border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 14.sp(context),
            color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
