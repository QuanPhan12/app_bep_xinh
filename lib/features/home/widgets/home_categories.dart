import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/material.dart';

class _CategoryModel {
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String actionId;

  const _CategoryModel({
    required this.title,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.actionId,
  });
}

/// Hàng danh mục phân loại món ăn nhanh (5 biểu tượng hình tròn theo Figma)
class HomeCategories extends StatelessWidget {
  final void Function(String categoryId)? onSelectCategory;

  const HomeCategories({
    super.key,
    this.onSelectCategory,
  });

  static const List<_CategoryModel> _categories = [
    _CategoryModel(
      title: 'Món mới',
      icon: Icons.local_fire_department_rounded,
      bgColor: Color(0xFFFFECE8),
      iconColor: Color(0xFFFA5252),
      actionId: 'cat_new',
    ),
    _CategoryModel(
      title: 'Eat Clean',
      icon: Icons.spa_rounded,
      bgColor: Color(0xFFEBFBEE),
      iconColor: AppColors.secondary,
      actionId: 'cat_eat_clean',
    ),
    _CategoryModel(
      title: 'Nấu nhanh',
      icon: Icons.bolt_rounded,
      bgColor: Color(0xFFE7F5FF),
      iconColor: Color(0xFF1971C2),
      actionId: 'cat_fast',
    ),
    _CategoryModel(
      title: 'Món nước',
      icon: Icons.soup_kitchen_rounded,
      bgColor: Color(0xFFFFF4E6),
      iconColor: AppColors.primary,
      actionId: 'cat_soup',
    ),
    _CategoryModel(
      title: 'Món chay',
      icon: Icons.grass_rounded,
      bgColor: Color(0xFFE6FCF5),
      iconColor: Color(0xFF0CA678),
      actionId: 'cat_vegetarian',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppConstants.maxContentWidth,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _categories.map((cat) {
              return AppTap(
                actionName: 'home_category_${cat.actionId}',
                onTap: () {
                  if (onSelectCategory != null) {
                    onSelectCategory!(cat.actionId);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52.w(context),
                      height: 52.w(context),
                      decoration: BoxDecoration(
                        color: cat.bgColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cat.iconColor.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        cat.icon,
                        color: cat.iconColor,
                        size: 24.sp(context),
                      ),
                    ),
                    SizedBox(height: 6.h(context)),
                    Text(
                      cat.title,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontSize: 12.sp(context),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
