import '../../../sollume/shared/app_menu_tile.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/widgets/app_menu_group.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

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
import 'package:app_bep_xinh/core/widgets/app_appearance_picker.dart';
import 'package:app_bep_xinh/features/profile/services/profile_service.dart';

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
      try {
        // Hoàn tất đăng xuất SDK trước khi rời màn hình; lỗi mạng không được báo thành công.
        await context.read<AuthService>().signOut();
        if (context.mounted) context.go(PathRouter.loginScreen);
      } catch (error) {
        if (context.mounted) {
          AppMessenger.showError(context, authErrorMessage(error));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppSliverAppBar(
      title: 'Cài đặt',
      onBackPressed: () {
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
              return AppContentScrollView(
                padding: const EdgeInsets.all(16),
                children: [
                  AppMenuGroup(
                    title: 'Tài khoản',
                    children: [
                      AppMenuTile(
                        leadingIcon: PhosphorIconsRegular.userCircle,
                        title: 'Chỉnh sửa hồ sơ',
                        subtitle: state.account!.name,
                        onTap: context.onAppTap(() {
                          context.push(PathRouter.profileEditScreen);
                        }, actionName: 'settings_edit_profile'),
                      ),
                      AppMenuTile(
                        leadingIcon: PhosphorIconsRegular.article,
                        title: 'Quản lý bài đăng',
                        subtitle: 'Bài đã đăng, chờ duyệt và bài đã ẩn',
                        onTap: context.onAppTap(() {
                          context.push(PathRouter.recipeSubmissionsScreen);
                        }, actionName: 'settings_recipe_submissions'),
                      ),
                      AppMenuTile(
                        leadingIcon: PhosphorIconsRegular.lockKey,
                        title: 'Đổi mật khẩu',
                        onTap: () {
                          context.push('/settings/password');
                        },
                      ),
                    ],
                  ),
                  AppMenuGroup(
                    title: 'Quyền riêng tư',
                    children: [
                      SwitchListTile.adaptive(
                        key: const ValueKey('settings_show_bio'),
                        title: const Text('Hiển thị giới thiệu'),
                        subtitle: const Text(
                          'Cho phép người khác xem phần giới thiệu trên hồ sơ',
                        ),
                        value: state.account!.showBio,
                        onChanged: state.saving
                            ? null
                            : context.read<SettingsCubit>().setShowBio,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const AppSectionHeader(title: 'Giao diện ứng dụng'),
                  const AppAppearancePicker(),
                  const SizedBox(height: 12),
                  AppMenuGroup(
                    title: 'Thông tin',
                    children: [
                      AppMenuTile(
                        leadingIcon: PhosphorIconsRegular.fileText,
                        title: 'Điều khoản dịch vụ',
                        onTap: () {
                          context.push('/legal/terms');
                        },
                      ),
                      AppMenuTile(
                        leadingIcon: PhosphorIconsRegular.shieldCheck,
                        title: 'Chính sách bảo mật',
                        onTap: () {
                          context.push('/legal/privacy');
                        },
                      ),
                    ],
                  ),
                  AppCard(
                    showBorder: false,
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        leading: Icon(
                          PhosphorIconsRegular.info,
                          color: context.colors.textSecondary,
                        ),
                        title: Text(
                          'Về ${AppConstants.appName}',
                          style: AppTextStyles.titleSmall,
                        ),
                        subtitle: Text(
                          'Phiên bản ${AppConstants.appVersion}',
                          style: AppTextStyles.bodySmall,
                        ),
                        trailing: Icon(
                          PhosphorIconsRegular.caretRight,
                          color: context.colors.textTertiary,
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
