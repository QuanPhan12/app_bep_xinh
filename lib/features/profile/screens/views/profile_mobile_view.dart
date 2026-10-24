import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_assets.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Giao diện Trang cá nhân (Mobile View)
class ProfileMobileView extends StatelessWidget {
  const ProfileMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Trang cá nhân',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
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
              children: [
                // Thẻ hồ sơ đầu bếp
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64.w(context),
                            height: 64.w(context),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                              image: const DecorationImage(
                                image: AssetImage(AppAssets.logo),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w(context)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Mai Anh',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(width: 4.w(context)),
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2.h(context)),
                                Text(
                                  'Bếp trưởng gia đình • Yêu Eat Clean',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(context, '18', 'Công thức'),
                          _buildStatItem(context, '4', 'Bộ sưu tập'),
                          _buildStatItem(context, '1.2k', 'Theo dõi'),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h(context)),

                // Menu tuỳ chọn
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.r(context)),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.bookmark_outline_rounded,
                        title: 'Món ăn đã lưu',
                        trailing: '24 món',
                        actionName: 'profile_saved_recipes',
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        context,
                        icon: Icons.collections_bookmark_outlined,
                        title: 'Bộ sưu tập ẩm thực',
                        trailing: '4 album',
                        actionName: 'profile_collections',
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        context,
                        icon: CupertinoIcons.time,
                        title: 'Lịch sử nấu ăn',
                        actionName: 'profile_history',
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        context,
                        icon: Icons.shield_outlined,
                        title: 'Tài khoản & Bảo mật',
                        actionName: 'profile_security',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h(context)),

                // Nút Đăng xuất
                AppTap(
                  actionName: 'profile_logout',
                  onTap: () {
                    context.replace(PathRouter.loginScreen);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14.h(context)),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(14.r(context)),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded,
                            color: AppColors.error, size: 18),
                        SizedBox(width: 8.w(context)),
                        Text(
                          'Đăng xuất',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 2.h(context)),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailing,
    required String actionName,
  }) {
    return AppTap(
      actionName: actionName,
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w(context),
          vertical: 14.h(context),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            SizedBox(width: 14.w(context)),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              SizedBox(width: 6.w(context)),
            ],
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textTertiary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
