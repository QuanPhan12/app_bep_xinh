import 'package:flutter_bloc/flutter_bloc.dart';

import '../../validation/validation.dart';
import 'register.dart';

/// Cubit quản lý toàn bộ nghiệp vụ đăng ký (Chuẩn BLoC Architecture)
class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit() : super(const RegisterState());

  /// Người dùng thay đổi Tên hiển thị
  void nameChanged(String name) {
    emit(
      state.copyWith(
        name: name,
        status: RegisterStatus.initial,
        errorMessage: null,
      ),
    );
  }

  /// Người dùng thay đổi Email
  void emailChanged(String email) {
    emit(
      state.copyWith(
        email: email,
        status: RegisterStatus.initial,
        errorMessage: null,
      ),
    );
  }

  /// Người dùng thay đổi Mật khẩu
  void passwordChanged(String password) {
    emit(
      state.copyWith(
        password: password,
        status: RegisterStatus.initial,
        errorMessage: null,
      ),
    );
  }

  /// Người dùng thay đổi Mật khẩu xác nhận
  void confirmPasswordChanged(String confirmPassword) {
    emit(
      state.copyWith(
        confirmPassword: confirmPassword,
        status: RegisterStatus.initial,
        errorMessage: null,
      ),
    );
  }

  /// Ẩn / Hiện mật khẩu
  void togglePasswordVisibility() {
    emit(state.copyWith(isPasswordObscured: !state.isPasswordObscured));
  }

  /// Ẩn / Hiện mật khẩu xác nhận
  void toggleConfirmPasswordVisibility() {
    emit(
      state.copyWith(
        isConfirmPasswordObscured: !state.isConfirmPasswordObscured,
      ),
    );
  }

  /// Thay đổi trạng thái đồng ý điều khoản
  void termsAcceptedChanged(bool? value) {
    emit(
      state.copyWith(
        isTermsAccepted: value ?? !state.isTermsAccepted,
        status: RegisterStatus.initial,
        errorMessage: null,
      ),
    );
  }

  /// Bật / Tắt đồng ý điều khoản
  void toggleTermsAccepted() {
    emit(
      state.copyWith(
        isTermsAccepted: !state.isTermsAccepted,
        status: RegisterStatus.initial,
        errorMessage: null,
      ),
    );
  }

  /// Thực hiện đăng ký tài khoản
  Future<void> submitRegister() async {
    final name = state.name.trim();
    final email = state.email.trim();
    final password = state.password.trim();
    final confirmPassword = state.confirmPassword.isNotEmpty
        ? state.confirmPassword.trim()
        : null;

    final validationMessage = Validation.getRegisterValidationErrors(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      isTermsAccepted: state.isTermsAccepted,
    );

    if (validationMessage != null) {
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: validationMessage,
        ),
      );
      return;
    }

    emit(state.copyWith(status: RegisterStatus.loading));

    try {
      // Giả lập gọi API Auth Service / Repository
      await Future.delayed(const Duration(seconds: 1));

      // Đăng ký thành công
      emit(state.copyWith(status: RegisterStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: 'Đã có lỗi xảy ra: ${e.toString()}',
        ),
      );
    }
  }
}
