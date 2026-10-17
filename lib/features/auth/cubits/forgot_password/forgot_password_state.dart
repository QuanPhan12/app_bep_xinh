/// Trạng thái của tiến trình quên mật khẩu
enum ForgotPasswordStatus { initial, loading, success, failure }

/// State bất biến đại diện cho toàn bộ trạng thái của ForgotPasswordForm
class ForgotPasswordState {
  final String email;
  final ForgotPasswordStatus status;
  final String? errorMessage;
  final bool isEmailSent;

  const ForgotPasswordState({
    this.email = '',
    this.status = ForgotPasswordStatus.initial,
    this.errorMessage,
    this.isEmailSent = false,
  });

  /// Kiểm tra email có dữ liệu hay không
  bool get isValid => email.trim().isNotEmpty;

  /// Tạo bản sao State mới khi có sự thay đổi
  ForgotPasswordState copyWith({
    String? email,
    ForgotPasswordStatus? status,
    String? errorMessage,
    bool? isEmailSent,
  }) {
    return ForgotPasswordState(
      email: email ?? this.email,
      status: status ?? this.status,
      errorMessage: errorMessage,
      isEmailSent: isEmailSent ?? this.isEmailSent,
    );
  }
}
