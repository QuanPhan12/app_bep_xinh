import 'package:flutter/foundation.dart';

abstract interface class AuthService {
  Listenable get sessionChanges;
  String? get userId;
  Future<void> signIn(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> register(String name, String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
}

/// Người dùng đóng bộ chọn tài khoản; không coi đây là đăng nhập thất bại.
class AuthCancelled implements Exception {
  const AuthCancelled();
}

String authErrorMessage(Object error) => error is AuthFailure
    ? error.message
    : 'Không thể kết nối. Vui lòng thử lại.';
