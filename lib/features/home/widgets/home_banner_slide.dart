import 'dart:async';

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/material.dart';

import '../models/home_banner_item.dart';

/// Chỉ hiển thị một slide; không sở hữu timer hay trạng thái carousel.
class HomeBannerSlide extends StatelessWidget {
  final HomeBannerItem banner;
  final FutureOr<void> Function()? onTap;

  const HomeBannerSlide({super.key, required this.banner, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16.r(context));
    return AppTap(
      actionName: 'home_hero_banner_tap',
      params: {'banner_id': banner.id},
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pixels =
                  (constraints.maxWidth *
                          MediaQuery.devicePixelRatioOf(context))
                      .round()
                      .clamp(1, 2048);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    banner.image,
                    fit: BoxFit.cover,
                    cacheWidth: pixels,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: AppColors.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: AppColors.textTertiary,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
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
                  Padding(
                    padding: EdgeInsets.all(14.w(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Wrap(
                          spacing: 6.w(context),
                          runSpacing: 4,
                          children: [
                            _BannerTag(text: banner.tag, primary: true),
                            _BannerTag(text: banner.cookTime),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  banner.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 4.h(context)),
                              Text(
                                banner.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BannerTag extends StatelessWidget {
  final String text;
  final bool primary;
  const _BannerTag({required this.text, this.primary = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: 8.w(context),
      vertical: 4.h(context),
    ),
    decoration: BoxDecoration(
      color: primary ? AppColors.primary : Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(6.r(context)),
      border: primary
          ? null
          : Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.5),
    ),
    child: Text(
      text,
      style: AppTextStyles.labelSmall.copyWith(
        color: Colors.white,
        fontWeight: primary ? FontWeight.bold : FontWeight.w500,
        fontSize: 11,
      ),
    ),
  );
}
