import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/services/auth_service.dart';
import '../../auth/services/password_service.dart';

class PasswordState {
  final String current, password, confirm;
  final bool busy, saved;
  final String? error;
  const PasswordState({
    this.current = '',
    this.password = '',
    this.confirm = '',
    this.busy = false,
    this.saved = false,
    this.error,
  });
}

class PasswordCubit extends Cubit<PasswordState> {
  final PasswordService service;
  PasswordCubit(this.service) : super(const PasswordState());
  void change({String? current, String? password, String? confirm}) {
    if (isClosed || state.busy) return;
    emit(
      PasswordState(
        current: current ?? state.current,
        password: password ?? state.password,
        confirm: confirm ?? state.confirm,
      ),
    );
  }

  Future<void> save() async {
    if (isClosed || state.busy || state.saved) return;
    final value = state;
    String? error;
    if (value.current.isEmpty) {
      error = 'Nhập mật khẩu hiện tại.';
    } else if (value.password.length < 6 || value.password.length > 128) {
      error = 'Mật khẩu mới từ 6 đến 128 ký tự.';
    } else if (value.current == value.password) {
      error = 'Mật khẩu mới phải khác mật khẩu hiện tại.';
    } else if (value.password != value.confirm) {
      error = 'Mật khẩu xác nhận không khớp.';
    }
    if (error != null) {
      emit(
        PasswordState(
          current: value.current,
          password: value.password,
          confirm: value.confirm,
          error: error,
        ),
      );
      return;
    }
    emit(
      PasswordState(
        current: value.current,
        password: value.password,
        confirm: value.confirm,
        busy: true,
      ),
    );
    try {
      await service.changePassword(value.current, value.password);
      if (!isClosed) emit(const PasswordState(saved: true));
    } catch (e) {
      if (!isClosed) {
        emit(
          PasswordState(
            current: value.current,
            password: value.password,
            confirm: value.confirm,
            error: authErrorMessage(e),
          ),
        );
      }
    }
  }
}
