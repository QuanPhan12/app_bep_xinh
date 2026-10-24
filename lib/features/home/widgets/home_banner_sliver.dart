import 'dart:async';

import 'package:flutter/material.dart';

import '../models/home_banner_item.dart';
import 'home_banner.dart';

/// Dừng autoplay khi banner đã cuộn ra khỏi viewport.
class HomeBannerSliver extends StatelessWidget {
  final List<HomeBannerItem> banners;
  final FutureOr<void> Function(String)? onTap;
  const HomeBannerSliver({super.key, required this.banners, this.onTap});

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) => SliverToBoxAdapter(
      child: HomeBanner(
        banners: banners,
        onTap: onTap,
        isVisible:
            constraints.remainingPaintExtent > 0 &&
            constraints.scrollOffset < HomeBanner.heightOf(context) + 16,
      ),
    ),
  );
}
