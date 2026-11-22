import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/text_styles/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_messenger.dart';
import '../models/account_access.dart';
import '../services/auth_service.dart';

class AccountAccessScreen extends StatelessWidget {
  const AccountAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return ListenableBuilder(
      listenable: auth.sessionChanges,
      builder: (context, _) {
        final access = (auth as AccountSessionAccess).accountAccess;
        final checking = access.status == AccountAccessStatus.checking;
        final locked = access.status == AccountAccessStatus.locked;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (checking)
                        const CircularProgressIndicator()
                      else
                        Icon(
                          locked
                              ? Icons.lock_outline
                              : Icons.cloud_off_outlined,
                          size: 56,
                          color: AppColors.primary,
                        ),
                      const SizedBox(height: 24),
                      Text(
                        checking
                            ? 'Đang kiểm tra tài khoản'
                            : locked
                            ? 'Tài khoản bị khóa'
                            : 'Chưa xác minh được tài khoản',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        checking
                            ? 'Vui lòng chờ xác nhận trạng thái tài khoản.'
                            : locked
                            ? 'Tài khoản hiện không thể truy cập ứng dụng. '
                                  'Vui lòng liên hệ quản trị viên để được hỗ trợ.'
                            : access.message ?? 'Kiểm tra kết nối và thử lại.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
                      ),
                      if (locked &&
                          (access.message?.trim().isNotEmpty ?? false)) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Lý do: ${access.message}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 28),
                      if (locked) ...[
                        const Text(
                          'Đề nghị xem xét hoặc mở khóa:',
                          textAlign: TextAlign.center,
                        ),
                        const SelectableText(
                          'shuichiakaik5@gmail.com',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (!checking && !locked) ...[
                        AppButton(
                          text: 'Thử lại',
                          onPressed:
                              (auth as AccountSessionAccess).retryAccountAccess,
                          actionName: 'account_access_retry',
                        ),
                        const SizedBox(height: 12),
                      ],
                      AppButton(
                        text: 'Đăng xuất',
                        variant: AppButtonVariant.secondary,
                        // Luôn cho phép thoát, kể cả lần kiểm tra/đăng nhập đang chờ mạng.
                        allowConcurrent: true,
                        actionName: 'account_access_sign_out',
                        onPressed: () async {
                          try {
                            await auth.signOut();
                          } catch (error) {
                            if (context.mounted) {
                              AppMessenger.showError(
                                context,
                                authErrorMessage(error),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
