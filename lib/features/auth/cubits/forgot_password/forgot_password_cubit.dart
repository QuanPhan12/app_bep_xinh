import '../../services/auth_service.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../validation/validation.dart';
import 'forgot_password_state.dart';

/// Cubit quản lý toàn bộ nghiệp vụ quên mật khẩu (Chuẩn BLoC Architecture)
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthService service;

  ForgotPasswordCubit({required this.service})
    : super(const ForgotPasswordState());

  /// Người dùng thay đổi Email
  void emailChanged(String email) {
    if (isClosed || state.status == ForgotPasswordStatus.loading) return;
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
    if (isClosed || state.status == ForgotPasswordStatus.loading) return;
    emit(const ForgotPasswordState());
  }

  /// Thực hiện gửi yêu cầu khôi phục mật khẩu
  Future<void> submitForgotPassword() async {
    if (isClosed || state.status == ForgotPasswordStatus.loading) return;
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
      // Không suy ra sự tồn tại của tài khoản từ phản hồi gửi email.
      await service.sendPasswordReset(email);
      if (isClosed) return;

      emit(
        state.copyWith(status: ForgotPasswordStatus.success, isEmailSent: true),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ForgotPasswordStatus.failure,
          errorMessage: authErrorMessage(e),
        ),
      );
    }
  }
}
