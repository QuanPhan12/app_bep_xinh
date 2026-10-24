import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_assets.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class _BannerSlideData {
  final String id;
  final String title;
  final String description;
  final String image;
  final String tag;
  final String cookTime;

  const _BannerSlideData({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.tag,
    required this.cookTime,
  });
}

/// Banner gợi ý món ngon hôm nay (Featured Hero Banner Carousel)
/// Tích hợp thư viện carousel_slider chuẩn Production với autoPlay và lazy loading
class HomeBanner extends StatefulWidget {
  final ValueChanged<String>? onTap;

  const HomeBanner({super.key, this.onTap});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  static const List<_BannerSlideData> _banners = [
    _BannerSlideData(
      id: 'canh_suon_ham_rau_cu',
      title: 'Canh sườn hầm rau củ',
      description:
          'Vị ngọt thanh từ sườn non hầm mềm cùng bắp ngọt và rau củ tươi mát...',
      image: AppAssets.bannerCanhSuon,
      tag: 'Dễ làm',
      cookTime: '25 phút',
    ),
    _BannerSlideData(
      id: 'bo_ne_skillet',
      title: 'Bò né sốt tiêu đen',
      description:
          'Thịt bò xèo xèo cùng trứng ốp la béo ngậy và bánh mì nóng giòn...',
      image: AppAssets.dishBoNe,
      tag: 'Phổ biến',
      cookTime: '20 phút',
    ),
    _BannerSlideData(
      id: 'salad_uc_ga',
      title: 'Salad ức gà sốt mè',
      description:
          'Thanh đạm, giàu protein, giữ dáng tuyệt vời cho bữa ăn lành mạnh...',
      image: AppAssets.dishSaladGa,
      tag: 'Healthy',
      cookTime: '15 phút',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CarouselSlider.builder(
                carouselController: _carouselController,
                itemCount: _banners.length,
                itemBuilder: (context, index, realIndex) {
                  final banner = _banners[index];
                  return AppTap(
                    actionName: 'home_hero_banner_tap',
                    params: {'banner_id': banner.id, 'title': banner.title},
                    onTap: () => widget.onTap?.call(banner.id),
                    child: Container(
                      height: 160.h(context),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r(context)),
                        image: DecorationImage(
                          image: AssetImage(banner.image),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Lớp phủ Gradient tạo độ tương phản cho văn bản
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(16.r(context)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.2),
                                  Colors.black.withValues(alpha: 0.78),
                                ],
                              ),
                            ),
                          ),

                          // Nội dung Banner
                          Padding(
                            padding: EdgeInsets.all(14.w(context)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Các thẻ Tags (Badge)
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w(context),
                                        vertical: 4.h(context),
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(
                                          6.r(context),
                                        ),
                                      ),
                                      child: Text(
                                        banner.tag,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.sp(context),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 6.w(context)),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w(context),
                                        vertical: 4.h(context),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(
                                          6.r(context),
                                        ),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.3),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        banner.cookTime,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 11.sp(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Tiêu đề & mô tả món ăn
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      banner.title,
                                      style: AppTextStyles.titleLarge.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.sp(context),
                                        shadows: [
                                          Shadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.5),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 4.h(context)),
                                    Text(
                                      banner.description,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                        fontSize: 11.sp(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  height: 160.h(context),
                  viewportFraction: 1.0,
                  initialPage: 0,
                  enableInfiniteScroll: true,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 4),
                  autoPlayAnimationDuration:
                      const Duration(milliseconds: 700),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
              ),

              SizedBox(height: 8.h(context)),

              // Chỉ báo Dots Indicator chuyển động mượt mà
              AnimatedSmoothIndicator(
                activeIndex: _currentIndex,
                count: _banners.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 4.h(context),
                  dotWidth: 5.w(context),
                  expansionFactor: 3.5,
                  activeDotColor: AppColors.primary,
                  dotColor: AppColors.border,
                  spacing: 4.w(context),
                ),
                onDotClicked: (index) {
                  _carouselController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
