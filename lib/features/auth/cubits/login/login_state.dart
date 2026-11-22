/// Trạng thái của tiến trình đăng nhập
enum LoginStatus { initial, loading, success, failure }

enum LoginMethod { password, google }

/// State bất biến (Immutable State) đại diện cho toàn bộ trạng thái của LoginForm
class LoginState {
  final String email;
  final String password;
  final bool isPasswordObscured;
  final LoginStatus status;
  final LoginMethod method;
  final String? errorMessage;

  const LoginState({
    this.email = '',
    this.password = '',
    this.isPasswordObscured = true,
    this.status = LoginStatus.initial,
    this.method = LoginMethod.password,
    this.errorMessage,
  });

  /// Kiểm tra dữ liệu hợp lệ phía client
  bool get isValid => email.trim().isNotEmpty && password.isNotEmpty;

  /// Tạo bản sao State mới khi có sự thay đổi
  LoginState copyWith({
    String? email,
    String? password,
    bool? isPasswordObscured,
    LoginStatus? status,
    LoginMethod? method,
    String? errorMessage,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      status: status ?? this.status,
      method: method ?? this.method,
      errorMessage: errorMessage,
    );
  }
}
