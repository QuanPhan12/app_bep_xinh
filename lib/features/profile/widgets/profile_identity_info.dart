import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/app_avatar.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:flutter/material.dart';

class ProfileIdentityInfo extends StatelessWidget {
  final String name;
  final String handle;
  final String bio;
  final String? avatarAsset;
  final Widget? trailing;
  const ProfileIdentityInfo({
    super.key,
    required this.name,
    required this.handle,
    this.bio = '',
    this.avatarAsset,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          AppAvatar(name: name, assetPath: avatarAsset, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (handle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '@$handle',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
      if (bio.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(bio, style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary, height: 1.5)),
      ],
    ],
  );
}
