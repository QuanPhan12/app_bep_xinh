import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/colors/app_colors.dart';
import '../../../core/dimensions/dimensions.dart';
import '../../../core/text_styles/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../cubits/forgot_password/forgot_password.dart';
import 'login_text_field.dart';

/// Form xử lý quy trình quên mật khẩu (Chuẩn BLoC & Design System Bếp Xinh)
class ForgotPasswordForm extends StatelessWidget {
  final VoidCallback? onSuccess;

  const ForgotPasswordForm({super.key, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    final size = context.appSize;

    return BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case ForgotPasswordStatus.success:
            context.showSuccess(
              'Đã gửi liên kết khôi phục mật khẩu đến email của bạn!',
              title: 'Thành công',
            );
            onSuccess?.call();
          case ForgotPasswordStatus.failure:
            context.showWarning(
              state.errorMessage ?? 'Gửi yêu cầu thất bại. Vui lòng thử lại!',
              title: 'Thông báo',
            );
          case ForgotPasswordStatus.loading:
          case ForgotPasswordStatus.initial:
        }
      },
      child: BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
        builder: (context, state) {
          return AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: state.isEmailSent
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _buildInputView(context, size, state),
            secondChild: _buildSuccessView(context, size, state),
          );
        },
      ),
    );
  }

  /// Giao diện nhập email khi chưa gửi
  Widget _buildInputView(
    BuildContext context,
    AppSize size,
    ForgotPasswordState state,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nhập địa chỉ email liên kết với tài khoản Bếp Xinh của bạn. Chúng tôi sẽ gửi hướng dẫn khôi phục mật khẩu.',
          textAlign: TextAlign.left,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: size.space24.h(context)),

        // Ô nhập Email
        LoginTextField(
          label: 'Email đã đăng ký',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          height: 50.h(context),
          onChanged: context.read<ForgotPasswordCubit>().emailChanged,
        ),
        SizedBox(height: size.space20.h(context)),

        // Nút Gửi yêu cầu
        BlocSelector<ForgotPasswordCubit, ForgotPasswordState, bool>(
          selector: (s) => s.status == ForgotPasswordStatus.loading,
          builder: (context, isLoading) {
            return AppButton(
              text: 'Gửi liên kết khôi phục',
              icon: Icons.send_rounded,
              isLoading: isLoading,
              height: 50.h(context),
              actionName: 'btn_submit_forgot_password',
              requiresNetwork: true,
              throttleDuration: const Duration(milliseconds: 600),
              onPressed: context
                  .read<ForgotPasswordCubit>()
                  .submitForgotPassword,
            );
          },
        ),
        SizedBox(height: size.space20.h(context)),

        // Quay lại đăng nhập
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Nhớ mật khẩu? ',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppTap(
              actionName: 'btn_back_to_login_from_forgot',
              onTap: () => context.pop(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  'Đăng nhập ngay',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Giao diện thông báo sau khi đã gửi email thành công
  Widget _buildSuccessView(
    BuildContext context,
    AppSize size,
    ForgotPasswordState state,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon thành công
        Center(
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: AppColors.secondary,
            size: 38,
          ),
        ),
        SizedBox(height: size.space20.h(context)),

        // Tiêu đề
        Text(
          'Đã gửi email khôi phục!',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.secondary,
          ),
        ),
        SizedBox(height: size.space8.h(context)),

        // Nội dung mô tả kèm email người dùng
        Text.rich(
          TextSpan(
            text: 'Chúng tôi đã gửi hướng dẫn đặt lại mật khẩu đến:\n',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            children: [
              TextSpan(
                text: state.email,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(
                text: '\nVui lòng kiểm tra hộp thư đến hoặc mục thư rác (spam) của bạn.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: size.space24.h(context)),

        // Nút quay lại đăng nhập
        AppButton(
          text: 'Quay lại Đăng nhập',
          icon: Icons.arrow_back_rounded,
          height: 50.h(context),
          actionName: 'btn_back_to_login_success',
          onPressed: () => context.pop(),
        ),
        SizedBox(height: size.space16.h(context)),

        // Tùy chọn gửi lại
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Chưa nhận được email? ',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppTap(
              actionName: 'btn_resend_forgot_password',
              requiresNetwork: true,
              onTap: context.read<ForgotPasswordCubit>().submitForgotPassword,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(
                  'Gửi lại ngay',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
