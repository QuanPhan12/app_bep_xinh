import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_assets.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_button.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Giao diện Chi tiết món ăn (Mobile View) - Chuẩn Figma Frame 5
class RecipeDetailMobileView extends StatefulWidget {
  final String recipeId;

  const RecipeDetailMobileView({
    super.key,
    required this.recipeId,
  });

  @override
  State<RecipeDetailMobileView> createState() => _RecipeDetailMobileViewState();
}

class _RecipeDetailMobileViewState extends State<RecipeDetailMobileView> {
  int _portions = 2;
  int _selectedTabIndex = 0; // 0: Nguyên liệu, 1: Các bước nấu
  bool _isFavorite = false;

  final List<Map<String, String>> _ingredients = [
    {'name': 'Thịt bò thăn mềm thái mỏng', 'amount': '300g'},
    {'name': 'Trứng gà tươi', 'amount': '2 quả'},
    {'name': 'Tiêu đen Phú Quốc xay thô', 'amount': '1 thìa cà phê'},
    {'name': 'Bơ nhạt Anchor hảo hạng', 'amount': '20g'},
    {'name': 'Hành tây trắng thái múi cau', 'amount': '1/2 củ'},
    {'name': 'Pate gan heo truyền thống', 'amount': '50g'},
    {'name': 'Bánh mì nóng giòn', 'amount': '2 ổ'},
  ];

  final List<Map<String, String>> _steps = [
    {
      'step': 'Bước 1',
      'title': 'Sơ chế & Ướp thịt bò',
      'desc': 'Thịt bò thái lát mỏng, ướp với tỏi băm, dầu hào, nước tương, đường và 1 thìa tiêu đen xay trong 15 phút.',
    },
    {
      'step': 'Bước 2',
      'title': 'Làm nóng chảo gang',
      'desc': 'Đặt chảo gang con bò lên bếp đun thật nóng. Cho 15g bơ lạt vào đun chảy thơm lừng.',
    },
    {
      'step': 'Bước 3',
      'title': 'Áp chảo bò né & Trứng',
      'desc': 'Cho thịt bò đã ướp vào đảo nhanh tay ở lửa lớn trong 1 phút, đập trứng gà và cho pate vào một góc.',
    },
    {
      'step': 'Bước 4',
      'title': 'Hoàn thành & Thưởng thức',
      'desc': 'Rắc thêm hành tây, ngò rí, tiêu đen tươi lên trên. Nhấc chảo gang ra lót gỗ và thưởng thức kèm bánh mì nóng giòn.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: AppTap(
          actionName: 'recipe_detail_back',
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(PathRouter.homeScreen);
            }
          },
          child: const Center(
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 20),
          ),
        ),
        title: Text(
          'Chi Tiết Món Ăn',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? AppColors.error : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
          SizedBox(width: 8.w(context)),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w(context),
          vertical: 12.h(context),
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.maxContentWidth,
              ),
              child: AppButton(
                text: 'Bắt đầu nấu ngay (Hẹn giờ) ▶',
                actionName: 'recipe_start_cooking',
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh bìa món ăn kèm thẻ thông số
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.4,
                      child: Image.asset(
                        AppAssets.dishBoNe,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.restaurant, size: 64),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40.h(context),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: EdgeInsets.all(16.w(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên món ăn
                      Text(
                        'Bò né sốt tiêu đen bánh mì',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12.h(context)),

                      // Các thông số Meta
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetaChip(context, Icons.star_rounded, '4.9 (128)', AppColors.accent),
                          _buildMetaChip(context, CupertinoIcons.time, '20 phút', AppColors.primary),
                          _buildMetaChip(context, Icons.bolt_rounded, 'Dễ làm', AppColors.secondary),
                          _buildMetaChip(context, Icons.local_fire_department_rounded, '450 kcal', AppColors.warning),
                        ],
                      ),
                      const Divider(height: 28),

                      // Thông tin tác giả công thức
                      Row(
                        children: [
                          Container(
                            width: 44.w(context),
                            height: 44.w(context),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(AppAssets.logo),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w(context)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bếp Trưởng Mai Anh',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Tác giả công thức • 1.2k follower',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w(context),
                              vertical: 6.h(context),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary50,
                              borderRadius: BorderRadius.circular(20.r(context)),
                            ),
                            child: Text(
                              '+ Theo dõi',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),

                      // Tabs chuyển đổi: Nguyên liệu vs Các bước
                      Row(
                        children: [
                          Expanded(
                            child: AppTap(
                              actionName: 'recipe_tab_ingredients',
                              onTap: () => setState(() => _selectedTabIndex = 0),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10.h(context)),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _selectedTabIndex == 0
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Nguyên liệu (${_ingredients.length})',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: _selectedTabIndex == 0
                                        ? AppColors.primary
                                        : AppColors.textTertiary,
                                    fontWeight: _selectedTabIndex == 0
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: AppTap(
                              actionName: 'recipe_tab_steps',
                              onTap: () => setState(() => _selectedTabIndex = 1),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10.h(context)),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _selectedTabIndex == 1
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Các bước nấu (${_steps.length})',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: _selectedTabIndex == 1
                                        ? AppColors.primary
                                        : AppColors.textTertiary,
                                    fontWeight: _selectedTabIndex == 1
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h(context)),

                      // Khẩu phần ăn
                      if (_selectedTabIndex == 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số khẩu phần ăn:',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(20.r(context)),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed: () {
                                      if (_portions > 1) {
                                        setState(() => _portions--);
                                      }
                                    },
                                  ),
                                  Text(
                                    '$_portions người',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: () {
                                      setState(() => _portions++);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h(context)),

                        // Danh sách nguyên liệu
                        ..._ingredients.map((ing) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h(context)),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 12.w(context)),
                                Expanded(
                                  child: Text(
                                    ing['name']!,
                                    style: AppTextStyles.ingredientName,
                                  ),
                                ),
                                Text(
                                  ing['amount']!,
                                  style: AppTextStyles.ingredientAmount.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ] else ...[
                        // Danh sách các bước nấu
                        ..._steps.map((st) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 16.h(context)),
                            padding: EdgeInsets.all(14.w(context)),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14.r(context)),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w(context),
                                        vertical: 3.h(context),
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(6.r(context)),
                                      ),
                                      child: Text(
                                        st['step']!,
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w(context)),
                                    Expanded(
                                      child: Text(
                                        st['title']!,
                                        style: AppTextStyles.titleSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h(context)),
                                Text(
                                  st['desc']!,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(BuildContext context, IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 4.w(context)),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
