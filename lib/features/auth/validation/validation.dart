class Validation {
  const Validation._();

  static final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validate lỗi đăng nhập
  static String? getValidationErrors({String? email, String? password}) =>
      [validateEmail(email), validatePassword(password)].nonNulls.firstOrNull;

  /// Validate lỗi đăng ký
  static String? getRegisterValidationErrors({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    bool isTermsAccepted = true,
  }) =>
      [
        validateName(name),
        validateEmail(email),
        validatePassword(password),
        if (confirmPassword != null && password != confirmPassword)
          'Mật khẩu xác nhận không khớp',
        if (!isTermsAccepted)
          'Vui lòng đồng ý với Điều khoản dịch vụ và Chính sách bảo mật',
      ].nonNulls.firstOrNull;

  static String? validateName(String? value) => switch (value) {
    null => null,
    '' => 'Vui lòng nhập tên hiển thị',
    final v when v.trim().length < 2 => 'Tên hiển thị phải từ 2 ký tự trở lên',
    _ => null,
  };

  static String? validateEmail(String? value) => switch (value) {
    null => null,
    '' => 'Vui lòng nhập Email',
    final v when !_emailRegExp.hasMatch(v) => 'Email không hợp lệ',
    _ => null,
  };

  static String? validatePassword(String? value) => switch (value) {
    null => null,
    '' => 'Vui lòng nhập mật khẩu',
    final v when v.length < 6 => 'Mật khẩu phải từ 6 ký tự trở lên',
    _ => null,
  };
}
