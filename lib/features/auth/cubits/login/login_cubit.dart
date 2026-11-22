import '../../services/auth_service.dart';

import 'package:app_bep_xinh/features/auth/validation/validation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'login.dart';

/// Cubit quản lý toàn bộ nghiệp vụ đăng nhập (Chuẩn BLoC Architecture)
class LoginCubit extends Cubit<LoginState> {
  final AuthService service;

  LoginCubit({required this.service}) : super(const LoginState());

  /// Người dùng thay đổi Email
  void emailChanged(String email) {
    if (isClosed || state.status == LoginStatus.loading) return;
    emit(
      state.copyWith(
        email: email,
        status: LoginStatus.initial,
        errorMessage: null,
      ),
    );
  }

  /// Người dùng thay đổi Mật khẩu
  void passwordChanged(String password) {
    if (isClosed || state.status == LoginStatus.loading) return;
    emit(
      state.copyWith(
        password: password,
        status: LoginStatus.initial,
        errorMessage: null,
      ),
    );
  }

  /// Ẩn / Hiện mật khẩu
  void togglePasswordVisibility() {
    if (isClosed || state.status == LoginStatus.loading) return;
    emit(state.copyWith(isPasswordObscured: !state.isPasswordObscured));
  }

  /// Thực hiện đăng nhập
  Future<void> submitLogin() async {
    if (isClosed || state.status == LoginStatus.loading) return;
    final email = state.email.trim();
    final password = state.password;

    final validationMessage = Validation.getValidationErrors(
      email: email,
      password: password,
    );

    if (validationMessage != null) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: validationMessage,
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: LoginStatus.loading, method: LoginMethod.password),
    );

    try {
      // Cubit chỉ điều phối form; dịch vụ thực hiện xác thực thật.
      await service.signIn(email, password);
      if (isClosed) return;

      // Đăng nhập thành công
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: authErrorMessage(e),
        ),
      );
    }
  }

  Future<void> submitGoogleLogin() async {
    if (isClosed || state.status == LoginStatus.loading) return;
    emit(
      state.copyWith(status: LoginStatus.loading, method: LoginMethod.google),
    );
    try {
      await service.signInWithGoogle();
      if (!isClosed) emit(state.copyWith(status: LoginStatus.success));
    } on AuthCancelled {
      if (!isClosed) emit(state.copyWith(status: LoginStatus.initial));
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            errorMessage: authErrorMessage(error),
          ),
        );
      }
    }
  }
}
