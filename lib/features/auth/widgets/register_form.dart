import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/dimensions/dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/text_styles/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../cubits/register/register.dart';
import 'login_textfiled.dart';
import 'register_checkbox_procity.dart';

class RegisterForm extends StatelessWidget {
  final VoidCallback? onRegisterSuccess;

  const RegisterForm({super.key, this.onRegisterSuccess});

  @override
  Widget build(BuildContext context) {
    final size = context.appSize;

    return BlocListener<RegisterCubit, RegisterState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case RegisterStatus.success:
            context.showSuccess(
              'Tạo tài khoản thành công! Chào mừng bạn đến với Bếp Xinh.',
              title: 'Đăng ký thành công',
            );
            onRegisterSuccess?.call();
          case RegisterStatus.failure:
            context.showWarning(
              state.errorMessage ?? 'Đăng ký thất bại. Vui lòng thử lại!',
              title: 'Thông báo',
            );
          case RegisterStatus.loading:
          case RegisterStatus.initial:
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Tên hiển thị
          LoginTextField(
            label: 'Tên hiển thị',
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.text,
            height: 50.h(context),
            onChanged: context.read<RegisterCubit>().nameChanged,
          ),
          SizedBox(height: size.space16.h(context)),

          // 2. Email
          LoginTextField(
            label: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            height: 50.h(context),
            onChanged: context.read<RegisterCubit>().emailChanged,
          ),
          SizedBox(height: size.space16.h(context)),

          // 3. Mật khẩu
          BlocSelector<RegisterCubit, RegisterState, bool>(
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
                onChanged: context.read<RegisterCubit>().passwordChanged,
                onSuffixIconTap: context
                    .read<RegisterCubit>()
                    .togglePasswordVisibility,
              );
            },
          ),
          SizedBox(height: size.space16.h(context)),
          // 4. Mật khẩu lại
          BlocSelector<RegisterCubit, RegisterState, bool>(
            selector: (state) => state.isConfirmPasswordObscured,
            builder: (context, isObscured) {
              return LoginTextField(
                label: 'Xác nhận mật khẩu',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: isObscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                obscureText: isObscured,
                height: 50.h(context),
                onChanged: context.read<RegisterCubit>().confirmPasswordChanged,
                onSuffixIconTap: context
                    .read<RegisterCubit>()
                    .toggleConfirmPasswordVisibility,
              );
            },
          ),
          SizedBox(height: size.space16.h(context)),

          // 5. Đồng ý điều khoản & chính sách bảo mật
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const RegisterCheckboxProcity(),
          ),
          SizedBox(height: size.space24.h(context)),

          // 6. Nút Đăng ký
          BlocSelector<RegisterCubit, RegisterState, bool>(
            selector: (state) => state.status == RegisterStatus.loading,
            builder: (context, isLoading) {
              return AppButton(
                text: 'Đăng ký',
                isLoading: isLoading,
                height: 50.h(context),
                actionName: 'register_submit',
                requiresNetwork: true,
                throttleDuration: const Duration(milliseconds: 600),
                onPressed: context.read<RegisterCubit>().submitRegister,
              );
            },
          ),
          SizedBox(height: size.space24.h(context)),

          // 6. Đã có tài khoản -> Chuyển sang màn Đăng nhập
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Đã có tài khoản? ', style: AppTextStyles.labelMedium),
                AppTap(
                  actionName: 'btn_already_have_account',
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.pushReplacementNamed(NameRouter.loginScreen);
                    }
                  },
                  child: Text(
                    'Đăng nhập ngay',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: size.space16.h(context)),
        ],
      ),
    );
  }
}
