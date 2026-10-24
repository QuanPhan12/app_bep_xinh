import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_assets.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Header trên cùng của Trang chủ Bếp Xinh
/// Bao gồm: Logo thương hiệu + Tên app bên trái, Avatar người dùng bên phải
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Tên ứng dụng Bếp Xinh
          Row(
            children: [
              Container(
                width: 38.w(context),
                height: 38.w(context),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(10.r(context)),
                  border: Border.all(color: AppColors.primary100),
                ),
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  AppAssets.logo,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 10.w(context)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Bếp Xinh',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(width: 4.w(context)),
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.accent,
                        size: 16,
                      ),
                    ],
                  ),
                  Text(
                    'Hôm nay bạn nấu gì?',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Nút thông báo & Avatar người dùng
          Row(
            children: [
              AppTap(
                actionName: 'home_notification_tap',
                onTap: () {},
                child: Container(
                  width: 38.w(context),
                  height: 38.w(context),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.bell,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w(context)),
              AppTap(
                actionName: 'home_profile_avatar_tap',
                onTap: () {},
                child: Container(
                  width: 40.w(context),
                  height: 40.w(context),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    image: const DecorationImage(
                      image: AssetImage(AppAssets.logo),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
