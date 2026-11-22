import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../../core/utils/app_layout.dart';
import '../../../sollume/shared/app_text_field.dart' as sollume;
import '../../auth/services/auth_service.dart';
import '../../auth/services/password_service.dart';
import '../cubits/password_cubit.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final service = auth is PasswordService ? auth as PasswordService : null;
    return AppPageScaffold(
      appBar: AppSliverAppBar(
        title: 'Đổi mật khẩu',
        onBackPressed: () =>
            context.canPop() ? context.pop() : context.go('/settings'),
      ),
      body: service == null || !service.canChangePassword
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Bạn đang đăng nhập bằng nhà cung cấp khác. Vui lòng quản lý mật khẩu tại nhà cung cấp đó.',
              ),
            )
          : BlocProvider(
              create: (_) => PasswordCubit(service),
              child: const _PasswordForm(),
            ),
    );
  }
}

class _PasswordForm extends StatelessWidget {
  const _PasswordForm();
  @override
  Widget build(BuildContext context) =>
      BlocConsumer<PasswordCubit, PasswordState>(
        listener: (context, state) {
          if (state.saved) {
            AppMessenger.showSuccess(context, 'Đã đổi mật khẩu.');
            context.canPop() ? context.pop() : context.go('/settings');
          }
        },
        builder: (context, state) {
          final cubit = context.read<PasswordCubit>();
          return PopScope(
            canPop: !state.busy,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppLayout.formWidth(context),
                ),
                child: AppContentScrollView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Xác minh mật khẩu hiện tại để bảo vệ tài khoản của bạn.',
                    ),
                    const SizedBox(height: 24),
                    sollume.AppTextField(
                      key: const ValueKey('password_current'),
                      hintText: 'Mật khẩu hiện tại',
                      isPassword: true,
                      obscureText: true,
                      enabled: !state.busy,
                      onChanged: (v) => cubit.change(current: v),
                      autofillHints: const [AutofillHints.password],
                    ),
                    const SizedBox(height: 16),
                    sollume.AppTextField(
                      key: const ValueKey('password_new'),
                      hintText: 'Mật khẩu mới',
                      isPassword: true,
                      obscureText: true,
                      enabled: !state.busy,
                      onChanged: (v) => cubit.change(password: v),
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    const SizedBox(height: 16),
                    sollume.AppTextField(
                      key: const ValueKey('password_confirm'),
                      hintText: 'Nhập lại mật khẩu mới',
                      isPassword: true,
                      obscureText: true,
                      enabled: !state.busy,
                      onChanged: (v) => cubit.change(confirm: v),
                      autofillHints: const [AutofillHints.newPassword],
                    ),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          state.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: 'Đổi mật khẩu',
                      onPressed: cubit.save,
                      isLoading: state.busy,
                      actionName: 'settings_change_password',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}
