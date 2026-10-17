import 'package:flutter_bloc/flutter_bloc.dart';

import '../../validation/validation.dart';
import 'forgot_password_state.dart';

/// Cubit quản lý toàn bộ nghiệp vụ quên mật khẩu (Chuẩn BLoC Architecture)
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit() : super(const ForgotPasswordState());

  /// Người dùng thay đổi Email
  void emailChanged(String email) {
    emit(
      state.copyWith(
        email: email,
        status: ForgotPasswordStatus.initial,
        errorMessage: null,
      ),
    );
  }

  /// Đặt lại trạng thái để gửi lại hoặc nhập email khác
  void resetState() {
    emit(const ForgotPasswordState());
  }

  /// Thực hiện gửi yêu cầu khôi phục mật khẩu
  Future<void> submitForgotPassword() async {
    final email = state.email.trim();

    final validationMessage = Validation.getForgotPasswordValidationErrors(
      email: email,
    );

    if (validationMessage != null) {
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: validationMessage,
        ),
      );
      return;
    }

    emit(state.copyWith(status: ForgotPasswordStatus.loading));

    try {
      // Giả lập gọi API gửi email khôi phục mật khẩu
      await Future.delayed(const Duration(seconds: 1));

      emit(
        state.copyWith(
          status: ForgotPasswordStatus.success,
          isEmailSent: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: 'Đã có lỗi xảy ra: ${e.toString()}',
        ),
      );
    }
  }
}
