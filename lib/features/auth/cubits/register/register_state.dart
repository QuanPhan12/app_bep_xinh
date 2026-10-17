import 'package:equatable/equatable.dart';

/// Trạng thái của tiến trình đăng ký
enum RegisterStatus { initial, loading, success, failure }

/// State bất biến (Immutable State) đại diện cho toàn bộ trạng thái của RegisterForm
class RegisterState extends Equatable {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isPasswordObscured;
  final bool isConfirmPasswordObscured;
  final bool isTermsAccepted;
  final RegisterStatus status;
  final String? errorMessage;

  const RegisterState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isPasswordObscured = true,
    this.isConfirmPasswordObscured = true,
    this.isTermsAccepted = false,
    this.status = RegisterStatus.initial,
    this.errorMessage,
  });

  /// Kiểm tra dữ liệu hợp lệ phía client
  bool get isValid =>
      name.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      password.isNotEmpty &&
      isTermsAccepted;

  /// Tạo bản sao State mới khi có sự thay đổi
  RegisterState copyWith({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isPasswordObscured,
    bool? isConfirmPasswordObscured,
    bool? isTermsAccepted,
    RegisterStatus? status,
    String? errorMessage,
  }) {
    return RegisterState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      isConfirmPasswordObscured:
          isConfirmPasswordObscured ?? this.isConfirmPasswordObscured,
      isTermsAccepted: isTermsAccepted ?? this.isTermsAccepted,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        name,
        email,
        password,
        confirmPassword,
        isPasswordObscured,
        isConfirmPasswordObscured,
        isTermsAccepted,
        status,
        errorMessage,
      ];
}
