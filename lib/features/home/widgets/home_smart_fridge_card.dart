import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/material.dart';

/// Thẻ gợi ý "Tủ lạnh thông minh" (Smart Fridge Recommendation Card)
/// Giúp người dùng nấu ăn từ nguyên liệu sẵn có trong tủ lạnh
class HomeSmartFridgeCard extends StatelessWidget {
  final VoidCallback? onExploreTap;

  const HomeSmartFridgeCard({super.key, this.onExploreTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxContentWidth,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12.r(context)),
            ),
            padding: EdgeInsets.all(14.w(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header của thẻ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tủ lạnh thông minh',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp(context),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w(context),
                        vertical: 2.h(context),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4.r(context)),
                      ),
                      child: Text(
                        'Gợi ý',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.sp(context),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h(context)),

                // Mô tả nguyên liệu
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12.sp(context),
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'Gợi ý từ nguyên liệu của bạn:'),
                      TextSpan(
                        text: '(Trứng gà, Cà chua, Thịt bò...)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h(context)),

                // Hàng hành động: Số món nấu được + Nút Khám phá ngay
                Row(
                  children: [
                    Row(
                      children: [
                        Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w(context),
                            vertical: 6.h(context),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(8.r(context)),
                          ),
                          child: Text(
                            'Nấu được 3 món ngon',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    AppTap(
                      actionName: 'home_smart_fridge_explore_tap',
                      onTap: onExploreTap ?? () {},
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w(context),
                          vertical: 6.h(context),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(8.r(context)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Khám phá ngay',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.sp(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
