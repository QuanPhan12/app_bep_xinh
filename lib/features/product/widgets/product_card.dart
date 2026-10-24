import 'package:app_bep_xinh/core/widgets/app_card.dart';

import 'dart:async';

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Thẻ hiển thị sản phẩm / công thức món ăn (Product Card) của hệ thống Bếp Xinh
/// Được tách thành component dùng chung trong Feature Product
class ProductCard extends StatelessWidget {
  static const imageAspectRatio = 1.35;

  /// Giữ tỷ lệ mặc định khi đủ chỗ; dành thêm chiều cao cho chữ hệ thống lớn.
  static double minimumHeight(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    final contentWidth = width - 20.w(context);
    final metaRows = scaler.scale(11) * 7 + 33 > contentWidth ? 2 : 1;
    return width / imageAspectRatio +
        20.w(context) +
        scaler.scale(13) * 1.3 * 2 +
        6.h(context) +
        scaler.scale(11) * 1.5 * metaRows +
        (metaRows - 1) * 4 +
        4;
  }

  final RecipeItem recipe;
  final VoidCallback? onTap;
  final FutureOr<void> Function()? onFavoriteTap;

  const ProductCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppTap(
      actionName: 'product_card_tap',
      params: {'recipe_id': recipe.id, 'title': recipe.title},
      onTap: onTap,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm kèm nút Yêu thích & Tag
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: imageAspectRatio,
                  child: LayoutBuilder(
                    builder: (context, constraints) => Image.asset(
                      recipe.image,
                      fit: BoxFit.cover,
                      cacheWidth:
                          (constraints.maxWidth *
                                  MediaQuery.devicePixelRatioOf(context))
                              .round()
                              .clamp(1, 2048),
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Icons.restaurant,
                            color: AppColors.textTertiary,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Tag danh mục nổi góc trái trên ảnh
                Positioned(
                  top: 8.h(context),
                  left: 8.w(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w(context),
                      vertical: 3.h(context),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6.r(context)),
                    ),
                    child: Text(
                      recipe.tag,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Nút Trái tim yêu thích góc phải trên ảnh
                Positioned(
                  top: 8.h(context),
                  right: 8.w(context),
                  child: AppTap(
                    actionName: 'product_favorite_tap',
                    params: {'recipe_id': recipe.id},
                    onTap: onFavoriteTap,
                    child: Container(
                      width: 28.w(context),
                      height: 28.w(context),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        recipe.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: recipe.isFavorite
                            ? AppColors.error
                            : AppColors.textSecondary,
                        size: 16.sp(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Thông tin chi tiết sản phẩm / món ăn
            Padding(
              padding: EdgeInsets.all(10.w(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên món ăn
                  Text(
                    recipe.title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h(context)),

                  // Hàng Đánh giá & Thời gian nấu
                  Wrap(
                    spacing: 6.w(context),
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.accent,
                            size: 15,
                          ),
                          SizedBox(width: 3.w(context)),
                          Text(
                            recipe.rating.toStringAsFixed(1),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '•',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.time,
                            color: AppColors.textTertiary,
                            size: 12,
                          ),
                          SizedBox(width: 3.w(context)),
                          Text(
                            '${recipe.cookTimeMinutes}p',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
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
  }
}
