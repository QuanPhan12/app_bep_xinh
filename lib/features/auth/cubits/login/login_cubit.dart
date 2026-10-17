import 'package:app_bep_xinh/features/auth/validation/validation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'login.dart';

/// Cubit quản lý toàn bộ nghiệp vụ đăng nhập (Chuẩn BLoC Architecture)
class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  /// Người dùng thay đổi Email
  void emailChanged(String email) {
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
    emit(state.copyWith(isPasswordObscured: !state.isPasswordObscured));
  }

  /// Thực hiện đăng nhập
  Future<void> submitLogin() async {
    final email = state.email.trim();
    final password = state.password.trim();

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

    emit(state.copyWith(status: LoginStatus.loading));

    try {
      // Giả lập gọi API Auth Service / Repository
      await Future.delayed(const Duration(seconds: 1));

      // Đăng nhập thành công
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Đã có lỗi xảy ra: ${e.toString()}',
        ),
      );
    }
  }
}
