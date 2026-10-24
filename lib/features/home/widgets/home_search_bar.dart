import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Thanh tìm kiếm thông minh trên Trang chủ
/// Tích hợp gợi ý nhanh và nút tìm kiếm màu cam đặc trưng
class HomeSearchBar extends StatelessWidget {
  final VoidCallback? onTap;

  const HomeSearchBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w(context)),
      child: AppTap(
        actionName: 'home_search_bar_tap',
        onTap: onTap ?? () {},
        child: Container(
          height: 48.h(context),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14.r(context)),
            // border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w(context)),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.search,
                color: AppColors.textTertiary,
                size: 20.sp(context),
              ),
              SizedBox(width: 10.w(context)),
              Expanded(
                child: Text(
                  'Hôm nay nấu gì?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 13.sp(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
