import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_button.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Giao diện Tủ lạnh thông minh (Mobile View) - Chuẩn Figma Frame 4
class FridgeMobileView extends StatefulWidget {
  const FridgeMobileView({super.key});

  @override
  State<FridgeMobileView> createState() => _FridgeMobileViewState();
}

class _FridgeMobileViewState extends State<FridgeMobileView> {
  final List<String> _selectedIngredients = [
    'Trứng gà',
    'Cà chua',
    'Thịt bò',
  ];

  final List<String> _popularIngredients = [
    'Thịt ba chỉ',
    'Nấm kim châm',
    'Súp lơ xanh',
    'Tôm tươi',
    'Đậu hũ non',
    'Cà rốt',
  ];

  void _addIngredient(String item) {
    if (!_selectedIngredients.contains(item)) {
      setState(() {
        _selectedIngredients.add(item);
      });
    }
  }

  void _removeIngredient(String item) {
    setState(() {
      _selectedIngredients.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.kitchen_rounded, color: AppColors.secondary),
            SizedBox(width: 8.w(context)),
            Text(
              'Tủ lạnh thông minh',
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
            icon: const Icon(CupertinoIcons.camera, color: AppColors.primary),
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
                // Banner giới thiệu
                Container(
                  padding: EdgeInsets.all(16.w(context)),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r(context)),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48.w(context),
                        height: 48.w(context),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      SizedBox(width: 14.w(context)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hôm nay tủ lạnh có gì?',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                            SizedBox(height: 4.h(context)),
                            Text(
                              'Chọn nguyên liệu sẵn có, Bếp Xinh AI sẽ tìm ngay món ngon phù hợp nhất!',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h(context)),

                // Nguyên liệu đang có trong tủ lạnh
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trong tủ lạnh (${_selectedIngredients.length})',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppTap(
                      actionName: 'fridge_clear_all',
                      onTap: () {
                        setState(() {
                          _selectedIngredients.clear();
                        });
                      },
                      child: Text(
                        'Xóa hết',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h(context)),

                Wrap(
                  spacing: 8.w(context),
                  runSpacing: 8.h(context),
                  children: _selectedIngredients.map((item) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w(context),
                        vertical: 6.h(context),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(20.r(context)),
                        border: Border.all(color: AppColors.primary200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6.w(context)),
                          AppTap(
                            actionName: 'fridge_remove_$item',
                            onTap: () => _removeIngredient(item),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.h(context)),

                // Nút tìm kiếm món nấu ngay
                AppButton(
                  text: 'Tìm món ngay (${_selectedIngredients.length * 4} công thức có thể nấu)',
                  actionName: 'fridge_find_recipes',
                  onPressed: () {},
                ),
                SizedBox(height: 24.h(context)),

                // Gợi ý nguyên liệu phổ biến
                Text(
                  'Thêm nguyên liệu phổ biến',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 10.h(context)),

                Wrap(
                  spacing: 8.w(context),
                  runSpacing: 8.h(context),
                  children: _popularIngredients.map((item) {
                    final isAdded = _selectedIngredients.contains(item);
                    return AppTap(
                      actionName: 'fridge_add_$item',
                      onTap: () => _addIngredient(item),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w(context),
                          vertical: 6.h(context),
                        ),
                        decoration: BoxDecoration(
                          color: isAdded
                              ? AppColors.surfaceVariant
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20.r(context)),
                          border: Border.all(
                            color: isAdded
                                ? AppColors.border
                                : AppColors.secondary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAdded ? Icons.check : Icons.add,
                              size: 14,
                              color: isAdded
                                  ? AppColors.textTertiary
                                  : AppColors.secondary,
                            ),
                            SizedBox(width: 4.w(context)),
                            Text(
                              item,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isAdded
                                    ? AppColors.textTertiary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 24.h(context)),

                // Mục "Nấu được ngay"
                Text(
                  'Nấu được ngay (100% nguyên liệu)',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h(context)),

                _buildRecipeSuggestionCard(
                  title: 'Đậu hũ sốt cà chua trứng',
                  cookTime: '15 phút',
                  rating: '4.9',
                  description: 'Thanh đạm, dễ làm, giàu dinh dưỡng cho bữa cơm gia đình.',
                ),
                SizedBox(height: 10.h(context)),

                _buildRecipeSuggestionCard(
                  title: 'Canh cà chua trứng đậu hũ',
                  cookTime: '20 phút',
                  rating: '4.8',
                  description: 'Vị chua ngọt thanh mát giải nhiệt ngày nắng.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeSuggestionCard({
    required String title,
    required String cookTime,
    required String rating,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w(context)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r(context)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54.w(context),
            height: 54.w(context),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(10.r(context)),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          SizedBox(width: 12.w(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h(context)),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h(context)),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.accent, size: 14),
                    SizedBox(width: 2.w(context)),
                    Text(rating, style: AppTextStyles.labelSmall),
                    SizedBox(width: 8.w(context)),
                    const Icon(CupertinoIcons.time,
                        color: AppColors.textTertiary, size: 12),
                    SizedBox(width: 2.w(context)),
                    Text(cookTime, style: AppTextStyles.labelSmall),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
