import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_tap.dart';
import 'package:flutter/material.dart';

/// Tiêu đề phân đoạn với nút hành động "Xem tất cả >"
class HomeLabelAction extends StatelessWidget {
  final String label;
  final String actionLabel;
  final VoidCallback? onActionTap;
  final Widget? customAction;

  const HomeLabelAction({
    super.key,
    required this.label,
    this.actionLabel = 'Xem tất cả',
    this.onActionTap,
    this.customAction,
  });

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
            children: [
              Text(
                label,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp(context),
                  color: AppColors.textPrimary,
                ),
              ),
              customAction ??
                  AppTap(
                    actionName: 'home_section_${label}_see_all',
                    onTap: onActionTap ?? () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp(context),
                          ),
                        ),
                        SizedBox(width: 2.w(context)),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.primary,
                          size: 11.sp(context),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
