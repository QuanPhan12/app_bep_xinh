import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/material.dart';

import '../models/home_category.dart';

class HomeCategories extends StatelessWidget {
  final List<HomeCategory> categories;
  final ValueChanged<String>? onSelectCategory;

  const HomeCategories({
    super.key,
    required this.categories,
    this.onSelectCategory,
  });

  // Icon và màu thuộc giao diện; tên và danh sách danh mục do service cung cấp.
  (IconData, Color, Color) _appearance(String icon) => switch (icon) {
    'new' => (
      Icons.local_fire_department_rounded,
      const Color(0xFFFFECE8),
      const Color(0xFFFA5252),
    ),
    'eat_clean' => (
      Icons.spa_rounded,
      const Color(0xFFEBFBEE),
      AppColors.secondary,
    ),
    'fast' => (
      Icons.bolt_rounded,
      const Color(0xFFE7F5FF),
      const Color(0xFF1971C2),
    ),
    'soup' => (
      Icons.soup_kitchen_rounded,
      const Color(0xFFFFF4E6),
      AppColors.primary,
    ),
    'vegetarian' => (
      Icons.grass_rounded,
      const Color(0xFFE6FCF5),
      const Color(0xFF0CA678),
    ),
    _ => (
      Icons.restaurant_rounded,
      AppColors.surfaceVariant,
      AppColors.textSecondary,
    ),
  };

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppConstants.maxContentWidth,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: categories.map((category) {
              final (icon, background, foreground) = _appearance(category.icon);
              return Flexible(
                child: AppTap(
                  actionName: 'home_category_${category.id}',
                  onTap: onSelectCategory == null
                      ? null
                      : () => onSelectCategory!(category.id),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52.w(context),
                        height: 52.w(context),
                        decoration: BoxDecoration(
                          color: background,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: foreground.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: foreground,
                          size: 24.sp(context),
                        ),
                      ),
                      SizedBox(height: 6.h(context)),
                      Text(
                        category.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 12.sp(context),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
