import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/dimensions/dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/text_styles/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../cubits/login/login.dart';
import 'login_text_field.dart';

class LoginForm extends StatelessWidget {
  final VoidCallback? onLoginSuccess;

  const LoginForm({super.key, this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    final size = context.appSize;

    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case LoginStatus.success:
            context.showSuccess(
              'Chào mừng bạn đã quay lại với Bếp Xinh!',
              title: 'Đăng nhập thành công',
            );
            onLoginSuccess?.call();
          case LoginStatus.failure:
            context.showWarning(
              state.errorMessage ?? 'Đăng nhập thất bại. Vui lòng thử lại!',
              title: 'Thông báo',
            );
          case LoginStatus.loading:
          case LoginStatus.initial:
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          //email
          LoginTextField(
            label: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            height: 50.h(context),
            onChanged: context.read<LoginCubit>().emailChanged,
          ),
          SizedBox(height: size.space16.h(context)),
          //password
          BlocSelector<LoginCubit, LoginState, bool>(
            selector: (state) => state.isPasswordObscured,
            builder: (context, isObscured) {
              return LoginTextField(
                label: 'Mật khẩu',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: isObscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                obscureText: isObscured,
                height: 50.h(context),
                onChanged: context.read<LoginCubit>().passwordChanged,
                onSuffixIconTap: context
                    .read<LoginCubit>()
                    .togglePasswordVisibility,
              );
            },
          ),
          SizedBox(height: size.space8.h(context)),

          Align(
            alignment: Alignment.centerRight,
            child: AppTap(
              actionName: 'btn_forgot_password',
              onTap: () {
                context.push(PathRouter.forgotPasswordScreen);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  'Quên mật khẩu?',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: size.space8.h(context)),

          BlocSelector<LoginCubit, LoginState, bool>(
            selector: (state) => state.status == LoginStatus.loading,
            builder: (context, isLoading) {
              return AppButton(
                text: 'Đăng nhập',
                isLoading: isLoading,
                height: 50.h(context),
                actionName: 'login_submit',
                requiresNetwork: true,
                throttleDuration: const Duration(milliseconds: 600),
                onPressed: context.read<LoginCubit>().submitLogin,
              );
            },
          ),
          SizedBox(height: size.space32.h(context)),

          // 5. Chưa có tài khoản -> Chuyển sang màn Đăng ký
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Chưa có tài khoản? ', style: AppTextStyles.labelMedium),
                AppTap(
                  actionName: 'btn_no_account',
                  onTap: () {
                    context.pushNamed(NameRouter.registerScreen);
                  },
                  child: Text(
                    'Đăng ký tại đây',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: size.space32.h(context)),
        ],
      ),
    );
  }
}
