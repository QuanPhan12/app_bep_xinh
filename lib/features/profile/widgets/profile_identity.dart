import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/tap/tap_extension.dart';
import 'package:app_bep_xinh/core/widgets/app_button.dart';
import 'package:app_bep_xinh/core/widgets/app_adaptive_columns.dart';

import '../models/profile_data.dart';
import 'profile_identity_info.dart';
import 'profile_cover.dart';

import 'package:app_bep_xinh/core/widgets/app_card.dart';

class ProfileIdentity extends StatelessWidget {
  final ProfileData data;
  final Future<void> Function() onEdit;
  final VoidCallback onCreateRecipe;
  final VoidCallback onSettings;
  const ProfileIdentity({
    super.key,
    required this.data,
    required this.onEdit,
    required this.onCreateRecipe,
    required this.onSettings,
  });
  @override
  Widget build(BuildContext context) {
    final account = data.account;
    return ProfileCover(
      child: AppAdaptiveColumns(
        primary: ProfileIdentityInfo(
          name: account.name,
          handle: account.handle,
          bio: account.showBio ? account.bio : '',
          avatarAsset: account.avatarAsset,
          trailing: IconButton(
            tooltip: 'Cài đặt',
            onPressed: context.onAppTap(
              onSettings,
              actionName: 'profile_settings',
            ),
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        secondary: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: data.ownRecipes.length,
                    label: 'Công thức',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    value: data.savedRecipes.length,
                    label: 'Đã lưu',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(value: account.cookedCount, label: 'Đã nấu'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Sửa hồ sơ',
                    variant: AppButtonVariant.secondary,
                    actionName: 'profile_edit',
                    onPressed: () {
                      unawaited(onEdit());
                    },
                    height: 42,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Đăng món',
                    actionName: 'profile_create_recipe',
                    onPressed: onCreateRecipe,
                    height: 42,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  const _Stat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppCard.radius),
    ),
    child: Column(
      children: [
        Text(
          '$value',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
