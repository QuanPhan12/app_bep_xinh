import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

class ProfileCover extends StatelessWidget {
  final Widget child;
  const ProfileCover({super.key, required this.child});
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'GÓC BẾP CÁ NHÂN',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primary,
            letterSpacing: .8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}
