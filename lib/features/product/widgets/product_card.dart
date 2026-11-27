import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:flutter/material.dart';

/// Thẻ hiển thị sản phẩm / công thức món ăn (Product Card) của hệ thống Bếp Xinh
/// Được tách thành component dùng chung trong Feature Product
class ProductCard extends StatelessWidget {
  static const imageAspectRatio = 1.35;

  /// Đo nội dung thật để grid/slider không kéo card theo tỷ lệ chiều cao cố định.
  static double contentHeight(
    BuildContext context,
    double width,
    RecipeItem recipe, {
    String? supportingText,
  }) {
    final padding = 10.w(context);
    final contentWidth = (width - padding * 2).clamp(1.0, double.infinity);
    Size measure(String text, TextStyle style, {int maxLines = 1}) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: maxLines,
        ellipsis: maxLines > 1 ? '…' : null,
      )..layout(maxWidth: contentWidth);
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final title = measure(
      recipe.title,
      AppTextStyles.titleSmall.copyWith(
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 2,
    );
    final metaStyle = AppTextStyles.labelSmall.copyWith(fontSize: 12);
    final time = measure('${recipe.cookTimeMinutes}p', metaStyle);
    final parts = <Size>[];
    if (recipe.rating > 0) {
      final rating = measure(
        recipe.rating.toStringAsFixed(1),
        metaStyle.copyWith(fontWeight: FontWeight.bold),
      );
      parts.add(
        Size(15 + 3.w(context) + rating.width, math.max(15, rating.height)),
      );
      parts.add(measure('•', const TextStyle(fontSize: 10)));
    }
    parts.add(Size(12 + 3.w(context) + time.width, math.max(12, time.height)));
    var rowWidth = 0.0;
    var rowHeight = 0.0;
    var metaHeight = 0.0;
    for (final part in parts) {
      final gap = rowWidth == 0 ? 0.0 : 6.w(context);
      if (rowWidth > 0 && rowWidth + gap + part.width > contentWidth) {
        metaHeight += rowHeight + 4;
        rowWidth = 0;
        rowHeight = 0;
      }
      rowWidth += (rowWidth == 0 ? 0 : 6.w(context)) + part.width;
      rowHeight = math.max(rowHeight, part.height);
    }
    metaHeight += rowHeight;
    final supportingHeight = supportingText == null
        ? 0.0
        : 8 +
              measure(
                supportingText,
                AppTextStyles.bodySmall.copyWith(fontSize: 12, height: 1.5),
                maxLines: 2,
              ).height;
    return (width / imageAspectRatio +
            padding * 2 +
            title.height +
            6.h(context) +
            metaHeight +
            supportingHeight +
            2)
        .ceilToDouble();
  }

  final RecipeItem recipe;
  final VoidCallback? onTap;
  final FutureOr<void> Function()? onFavoriteTap;
  final String? supportingText;

  const ProductCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onFavoriteTap,
    this.supportingText,
  });

  @override
  Widget build(BuildContext context) {
    return AppTap(
      actionName: 'product_card_tap',
      params: {'recipe_id': recipe.id, 'title': recipe.title},
      onTap: onTap,
      child: AppCard(
        showBorder: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm kèm nút Yêu thích & Tag
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: imageAspectRatio,
                  child: LayoutBuilder(
                    builder: (context, constraints) => Image(
                      image: ResizeImage.resizeIfNeeded(
                        (constraints.maxWidth *
                                MediaQuery.devicePixelRatioOf(context))
                            .round()
                            .clamp(1, 2048),
                        null,
                        recipe.image.startsWith('https://')
                            ? NetworkImage(recipe.image)
                            : AssetImage(recipe.image) as ImageProvider,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: context.colors.surfaceVariant,
                          child: Icon(
                            PhosphorIconsRegular.forkKnife,
                            color: context.colors.textTertiary,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Tag danh mục nổi góc trái trên ảnh
                if (recipe.tag.isNotEmpty)
                  Positioned(
                    top: 8.h(context),
                    left: 8.w(context),
                    right: (onFavoriteTap == null ? 8 : 64).w(context),
                    child: Align(
                      alignment: Alignment.centerLeft,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Nút Trái tim yêu thích góc phải trên ảnh
                if (onFavoriteTap != null)
                  Positioned(
                    top: 8.h(context),
                    right: 8.w(context),
                    child: Tooltip(
                      message: recipe.isFavorite ? 'Bỏ lưu món' : 'Lưu món',
                      child: Semantics(
                        button: true,
                        toggled: recipe.isFavorite,
                        child: AppTap(
                          actionName: 'product_favorite_tap',
                          requiresAuth: true,
                          params: {'recipe_id': recipe.id},
                          onTap: onFavoriteTap,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              recipe.isFavorite
                                  ? PhosphorIconsFill.heart
                                  : PhosphorIconsRegular.heart,
                              color: Colors.black87,
                              size: 16.sp(context),
                            ),
                          ),
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
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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
                      if (recipe.rating > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              PhosphorIconsFill.star,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 15,
                            ),
                            SizedBox(width: 3.w(context)),
                            Text(
                              recipe.rating.toStringAsFixed(1),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      if (recipe.rating > 0)
                        Text(
                          '•',
                          style: TextStyle(
                            color: context.colors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsRegular.clock,
                            color: context.colors.textTertiary,
                            size: 12,
                          ),
                          SizedBox(width: 3.w(context)),
                          Text(
                            '${recipe.cookTimeMinutes}p',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: context.colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (supportingText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      supportingText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        height: 1.5,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
