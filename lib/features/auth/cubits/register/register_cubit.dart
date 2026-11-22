import '../../services/auth_service.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../validation/validation.dart';
import 'register.dart';

/// Cubit quản lý toàn bộ nghiệp vụ đăng ký (Chuẩn BLoC Architecture)
class RegisterCubit extends Cubit<RegisterState> {
  final AuthService service;

  RegisterCubit({required this.service}) : super(const RegisterState());

  /// Người dùng thay đổi Tên hiển thị
  void nameChanged(String name) {
    if (isClosed || state.status == RegisterStatus.loading) return;
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
    if (isClosed || state.status == RegisterStatus.loading) return;
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
    if (isClosed || state.status == RegisterStatus.loading) return;
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
    if (isClosed || state.status == RegisterStatus.loading) return;
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
    if (isClosed || state.status == RegisterStatus.loading) return;
    emit(state.copyWith(isPasswordObscured: !state.isPasswordObscured));
  }

  /// Ẩn / Hiện mật khẩu xác nhận
  void toggleConfirmPasswordVisibility() {
    if (isClosed || state.status == RegisterStatus.loading) return;
    emit(
      state.copyWith(
        isConfirmPasswordObscured: !state.isConfirmPasswordObscured,
      ),
    );
  }

  /// Thay đổi trạng thái đồng ý điều khoản
  void termsAcceptedChanged(bool? value) {
    if (isClosed || state.status == RegisterStatus.loading) return;
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
    if (isClosed || state.status == RegisterStatus.loading) return;
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
    if (isClosed || state.status == RegisterStatus.loading) return;
    final name = state.name.trim();
    final email = state.email.trim();
    final password = state.password;
    final confirmPassword = state.confirmPassword;

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
      // Cubit chỉ điều phối form; dịch vụ thực hiện xác thực thật.
      await service.register(name, email, password);
      if (isClosed) return;

      // Đăng ký thành công
      emit(state.copyWith(status: RegisterStatus.success));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: authErrorMessage(e),
        ),
      );
    }
  }
}
