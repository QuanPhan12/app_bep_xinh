
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/tap/tap_extension.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/core/widgets/widgets.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';
import 'package:app_bep_xinh/features/profile/services/profile_service.dart';
import 'package:app_bep_xinh/features/profile/widgets/profile_edit_sheet.dart';

import '../cubits/settings/settings_cubit.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        SettingsCubit(service: context.read<ProfileService>())..load(),
    child: const _SettingsPage(),
  );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text(
          'Bạn có thể đăng nhập lại để tiếp tục sử dụng Bếp Xinh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.go(PathRouter.loginScreen);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppAppBar(
      title: 'Cài đặt',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(PathRouter.profileScreen);
        }
      },
    ),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppLayout.formWidth(context)),
          child: BlocConsumer<SettingsCubit, SettingsState>(
            listenWhen: (a, b) => a.noticeId != b.noticeId,
            listener: (context, state) {
              if (state.message != null) {
                AppMessenger.showError(context, state.message!);
              }
            },
            builder: (context, state) {
              if (state.account == null) {
                return AppLoadState(
                  isLoading: state.loading,
                  message: state.message,
                  onRetry: context.read<SettingsCubit>().load,
                );
              }
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const AppSectionHeader(title: 'Hồ sơ của bạn'),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(
                        children: [
                          ListTile(
                            leading: AppAvatar(
                              name: state.account!.name,
                              assetPath: state.account!.avatarAsset,
                              size: 44,
                            ),
                            title: Text(
                              state.account!.name,
                              style: AppTextStyles.titleSmall,
                            ),
                            subtitle: Text(
                              '@${state.account!.handle}',
                              style: AppTextStyles.bodySmall,
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textTertiary,
                            ),
                            onTap: context.onAppTap(() {
                              unawaited(
                                showProfileEditSheet(context, state.account!),
                              );
                            }, actionName: 'settings_edit_profile'),
                          ),
                          const Divider(indent: 16, endIndent: 16),
                          SwitchListTile.adaptive(
                            key: const ValueKey('settings_show_bio'),
                            title: Text(
                              'Hiển thị giới thiệu',
                              style: AppTextStyles.titleSmall,
                            ),
                            subtitle: Text(
                              'Hiện phần giới thiệu trên trang cá nhân.',
                              style: AppTextStyles.bodySmall,
                            ),
                            value: state.account!.showBio,
                            activeTrackColor: AppColors.primary,
                            onChanged: state.saving
                                ? null
                                : context.read<SettingsCubit>().setShowBio,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const AppSectionHeader(title: 'Ứng dụng'),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        leading: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.textSecondary,
                        ),
                        title: Text(
                          'Về ${AppConstants.appName}',
                          style: AppTextStyles.titleSmall,
                        ),
                        subtitle: Text(
                          'Phiên bản ${AppConstants.appVersion}',
                          style: AppTextStyles.bodySmall,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textTertiary,
                        ),
                        onTap: context.onAppTap(
                          () => showAboutDialog(
                            context: context,
                            applicationName: AppConstants.appName,
                            applicationVersion: AppConstants.appVersion,
                            children: [
                              Text(
                                AppConstants.appSlogan,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                          actionName: 'settings_about',
                          allowConcurrent: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    text: 'Đăng xuất',
                    variant: AppButtonVariant.secondary,
                    actionName: 'settings_logout',
                    allowConcurrent: true,
                    onPressed: state.saving ? null : () => _logout(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
