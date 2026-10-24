import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_button.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class _CartItem {
  final String name;
  final String amount;
  bool isChecked;

  _CartItem({
    required this.name,
    required this.amount,
    this.isChecked = false,
  });
}

/// Giao diện Giỏ đi chợ & Mua nguyên liệu (Mobile View)
class CartMobileView extends StatefulWidget {
  const CartMobileView({super.key});

  @override
  State<CartMobileView> createState() => _CartMobileViewState();
}

class _CartMobileViewState extends State<CartMobileView> {
  final List<_CartItem> _itemsM1 = [
    _CartItem(name: 'Sườn non heo sạch', amount: '500g', isChecked: true),
    _CartItem(name: 'Bắp ngọt Mỹ', amount: '2 bắp', isChecked: false),
    _CartItem(name: 'Cà rốt Đà Lạt', amount: '2 củ', isChecked: true),
    _CartItem(name: 'Khoai tây', amount: '3 củ', isChecked: false),
  ];

  final List<_CartItem> _itemsM2 = [
    _CartItem(name: 'Thịt thăn bò Úc', amount: '300g', isChecked: false),
    _CartItem(name: 'Trứng gà ta', amount: '4 quả', isChecked: true),
    _CartItem(name: 'Bơ nhạt Anchor', amount: '1 vỉ', isChecked: false),
    _CartItem(name: 'Bánh mì giòn', amount: '2 ổ', isChecked: false),
  ];

  @override
  Widget build(BuildContext context) {
    final checkedCount = _itemsM1.where((i) => i.isChecked).length +
        _itemsM2.where((i) => i.isChecked).length;
    final totalCount = _itemsM1.length + _itemsM2.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(CupertinoIcons.cart_fill, color: AppColors.primary),
            SizedBox(width: 8.w(context)),
            Text(
              'Giỏ đi chợ & Nguyên liệu',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          SizedBox(width: 8.w(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w(context),
          vertical: 16.h(context),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thẻ tiến độ mua sắm
                Container(
                  padding: EdgeInsets.all(16.w(context)),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r(context)),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50.w(context),
                        height: 50.w(context),
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$checkedCount/$totalCount',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w(context)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đã chuẩn bị $checkedCount trên $totalCount món',
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h(context)),
                            LinearProgressIndicator(
                              value: totalCount > 0 ? checkedCount / totalCount : 0,
                              backgroundColor: AppColors.surfaceVariant,
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h(context)),

                // Nhóm 1: Canh sườn hầm rau củ
                _buildRecipeGroup(
                  title: 'Canh sườn hầm rau củ',
                  items: _itemsM1,
                ),
                SizedBox(height: 18.h(context)),

                // Nhóm 2: Bò né sốt tiêu đen
                _buildRecipeGroup(
                  title: 'Bò né sốt tiêu đen bánh mì',
                  items: _itemsM2,
                ),
                SizedBox(height: 24.h(context)),

                // Nút hoàn thành
                AppButton(
                  text: 'Hoàn thành đi chợ ($checkedCount/$totalCount)',
                  actionName: 'cart_complete_checkout',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeGroup({
    required String title,
    required List<_CartItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r(context)),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.all(14.w(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.soup_kitchen_rounded,
                  color: AppColors.primary, size: 18),
              SizedBox(width: 8.w(context)),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...items.map((item) {
            return AppTap(
              actionName: 'cart_toggle_${item.name}',
              onTap: () {
                setState(() {
                  item.isChecked = !item.isChecked;
                });
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h(context)),
                child: Row(
                  children: [
                    Icon(
                      item.isChecked
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: item.isChecked
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      size: 20,
                    ),
                    SizedBox(width: 10.w(context)),
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          decoration: item.isChecked
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.isChecked
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      item.amount,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
