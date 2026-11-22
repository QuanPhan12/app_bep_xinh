import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'google_auth_client.dart';
import 'password_service.dart';

class FirebaseAuthService implements AuthService, PasswordService {
  final ValueNotifier<String?> _sessionChanges;
  @override
  Listenable get sessionChanges => _sessionChanges;
  final FirebaseAuth auth;
  final Future<void> Function(User user) prepareUser;
  final GoogleAuthClient googleAuth;
  late final StreamSubscription<User?> _subscription;
  bool _busy = false;
  bool _disposed = false;
  String? _unreadyUserId;

  FirebaseAuthService(
    this.auth, {
    required this.prepareUser,
    GoogleAuthClient? googleAuth,
  }) : googleAuth = googleAuth ?? PlatformGoogleAuthClient(),
       _sessionChanges = ValueNotifier(auth.currentUser?.uid) {
    _subscription = auth.authStateChanges().listen((_) {
      if (!_busy) _publish();
    });
  }

  @override
  String? get userId => _sessionChanges.value;

  void _publish() {
    if (_disposed) return;
    final uid = auth.currentUser?.uid;
    _sessionChanges.value = uid == _unreadyUserId ? null : uid;
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_disposed) throw const AuthFailure('Phiên làm việc đã kết thúc.');
    if (_busy) throw const AuthFailure('Vui lòng chờ thao tác hiện tại.');
    _busy = true;
    try {
      await operation();
    } on FirebaseAuthException catch (error) {
      if (const [
        'popup-closed-by-user',
        'cancelled-popup-request',
        'web-context-cancelled',
      ].contains(error.code)) {
        throw const AuthCancelled();
      }
      throw AuthFailure(messageForCode(error.code));
    } finally {
      _busy = false;
      _publish();
    }
  }

  @override
  Future<void> signIn(String email, String password) => _run(() async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _prepare(credential.user!, registration: false);
  });

  @override
  Future<void> signInWithGoogle() => _run(() async {
    final credential = await googleAuth.signIn(auth);
    final user = credential.user;
    if (user == null) {
      throw const AuthFailure('Chưa xác minh được tài khoản Google.');
    }
    // Dùng chung bước tạo/đọc hồ sơ; không ghi đè quyền hoặc trạng thái khóa đã có.
    await _prepare(
      user,
      registration: credential.additionalUserInfo?.isNewUser ?? false,
    );
  });

  @override
  Future<void> register(String name, String email, String password) =>
      _run(() async {
        final credential = await auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await _prepare(credential.user!, registration: true, name: name.trim());
      });

  Future<void> _prepare(
    User user, {
    required bool registration,
    String? name,
  }) async {
    _unreadyUserId = user.uid;
    try {
      if (name != null) await user.updateDisplayName(name);
      await prepareUser(user);
      _unreadyUserId = null;
    } catch (_) {
      // Auth và Firestore không có transaction chung. Giữ Auth để đăng nhập thử lại,
      // nhưng không công bố phiên thành công khi hồ sơ chưa được server xác nhận.
      try {
        await auth.signOut();
      } catch (_) {
        // Nếu SDK chưa đăng xuất được, UID chưa sẵn sàng vẫn bị chặn bởi _publish.
      }
      throw AuthFailure(
        registration
            ? 'Tài khoản đã được tạo nhưng chưa lưu được hồ sơ. Vui lòng đăng nhập để thử lại.'
            : 'Chưa tải được hồ sơ tài khoản. Vui lòng đăng nhập lại.',
      );
    }
  }

  @override
  Future<void> sendPasswordReset(String email) => _run(() async {
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      // Không tiết lộ email nào đã đăng ký, kể cả khi project chưa bật bảo vệ dò email.
      if (error.code != 'user-not-found') rethrow;
    }
  });

  @override
  Future<void> signOut() => _run(() async {
    await auth.signOut();
    await googleAuth.signOut();
  });

  @override
  bool get canChangePassword =>
      auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  @override
  Future<void> changePassword(String currentPassword, String newPassword) =>
      _run(() async {
        final user = auth.currentUser;
        if (user == null || !canChangePassword || user.email == null) {
          throw const AuthFailure(
            'Tài khoản này đăng nhập bằng nhà cung cấp khác. Hãy quản lý mật khẩu tại nhà cung cấp đó.',
          );
        }
        if (currentPassword.isEmpty ||
            newPassword.length < 6 ||
            newPassword.length > 128 ||
            newPassword == currentPassword) {
          throw const AuthFailure(
            'Chọn mật khẩu mới từ 6 đến 128 ký tự, khác mật khẩu hiện tại.',
          );
        }
        // Xác minh lại bằng mật khẩu cũ; phiên đăng nhập sẵn có không đủ quyền đổi mật khẩu.
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          ),
        );
        if (auth.currentUser?.uid != user.uid) {
          throw const AuthFailure('Phiên đăng nhập đã thay đổi.');
        }
        await user.updatePassword(newPassword);
      });

  static String messageForCode(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Email hoặc mật khẩu không đúng.',
    'email-already-in-use' => 'Email này đã được đăng ký.',
    'invalid-email' => 'Email không hợp lệ.',
    'weak-password' => 'Mật khẩu chưa đủ mạnh. Vui lòng chọn mật khẩu khác.',
    'requires-recent-login' => 'Vui lòng đăng nhập lại trước khi đổi mật khẩu.',
    'user-disabled' => 'Tài khoản đã bị vô hiệu hóa.',
    'too-many-requests' => 'Bạn thao tác quá nhiều. Vui lòng thử lại sau.',
    'network-request-failed' => 'Không có kết nối mạng. Vui lòng thử lại.',
    'operation-not-allowed' =>
      'Phương thức đăng nhập chưa được bật trên Firebase.',
    'popup-blocked' =>
      'Trình duyệt đã chặn cửa sổ Google. Vui lòng cho phép popup và thử lại.',
    'unauthorized-domain' =>
      'Đăng nhập Google chưa được hỗ trợ tại địa chỉ web này.',
    'account-exists-with-different-credential' => 'Email này đang dùng phương thức đăng nhập khác. Vui lòng đăng nhập bằng phương thức đã đăng ký.',
    _ => 'Không thể thực hiện yêu cầu. Vui lòng thử lại.',
  };

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription.cancel());
    _sessionChanges.dispose();
  }
}
