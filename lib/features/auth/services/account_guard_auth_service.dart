import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/account_access.dart';
import 'auth_service.dart';
import 'password_service.dart';

/// Kết hợp phiên Auth với trạng thái hồ sơ; không công bố UID chỉ vì mật khẩu đúng.
class AccountGuardAuthService
    implements AuthService, AccountSessionAccess, PasswordService {
  final ValueNotifier<int> _changes = ValueNotifier(0);
  final AuthService delegate;
  final AccountAccessSource source;
  final Duration verificationTimeout;
  StreamSubscription<AccountAccess>? _subscription;
  Timer? _timer;
  Completer<AccountAccess>? _settled;
  String? _uid;
  int _generation = 0;
  bool _disposed = false;
  AccountAccess _access = const AccountAccess(AccountAccessStatus.signedOut);

  AccountGuardAuthService({
    required this.delegate,
    required this.source,
    this.verificationTimeout = const Duration(seconds: 15),
  }) {
    delegate.sessionChanges.addListener(_sync);
    _sync();
  }

  @override
  Listenable get sessionChanges => _changes;
  @override
  AccountAccess get accountAccess => _access;
  @override
  String? get userId =>
      _access.status == AccountAccessStatus.active ? _uid : null;

  void _sync() {
    if (!_disposed && delegate.userId != _uid) _bind(delegate.userId);
  }

  void _bind(String? uid) {
    final generation = ++_generation;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _timer?.cancel();
    if (_settled case final pending? when !pending.isCompleted) {
      pending.complete(const AccountAccess(AccountAccessStatus.signedOut));
    }
    _settled = Completer<AccountAccess>();
    _uid = uid;
    if (uid == null) {
      _set(const AccountAccess(AccountAccessStatus.signedOut));
      return;
    }
    _set(const AccountAccess(AccountAccessStatus.checking));
    try {
      _subscription = source
          .watch(uid)
          .listen(
            (access) {
              // Kết quả từ tài khoản cũ không được mở lại phiên sau khi chuyển UID.
              if (_disposed || generation != _generation) return;
              if (access.status == AccountAccessStatus.signedOut) {
                _unavailable();
              } else {
                _set(access);
              }
            },
            onError: (Object _) {
              if (!_disposed && generation == _generation) _unavailable();
            },
            onDone: () {
              if (!_disposed && generation == _generation) _unavailable();
            },
          );
    } catch (_) {
      _unavailable();
    }
  }

  void _unavailable() => _set(
    const AccountAccess(
      AccountAccessStatus.unavailable,
      message:
          'Chưa xác minh được trạng thái tài khoản. Kiểm tra mạng và thử lại.',
    ),
  );

  void _set(AccountAccess next) {
    if (_disposed) return;
    final changed =
        _access.status != next.status || _access.message != next.message;
    _access = next;
    _timer?.cancel();
    if (next.status == AccountAccessStatus.checking) {
      _timer = Timer(verificationTimeout, _unavailable);
    } else if (_settled case final pending? when !pending.isCompleted) {
      pending.complete(next);
    }
    if (changed) _changes.value++;
  }

  Future<void> _requireActive() async {
    if (_disposed) throw const AuthFailure('Phiên làm việc đã kết thúc.');
    _sync();
    final uid = _uid;
    if (_access.status == AccountAccessStatus.checking) {
      await _settled?.future;
    }
    if (uid == null || uid != delegate.userId || _disposed) {
      throw const AuthFailure(
        'Phiên làm việc đã kết thúc. Vui lòng đăng nhập lại.',
      );
    }
    if (_access.status == AccountAccessStatus.locked) {
      throw const AuthFailure('Tài khoản đã bị khóa.');
    }
    if (_access.status != AccountAccessStatus.active) {
      throw AuthFailure(_access.message ?? 'Chưa xác minh được tài khoản.');
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    await delegate.signIn(email, password);
    await _requireActive();
  }

  @override
  Future<void> signInWithGoogle() async {
    await delegate.signInWithGoogle();
    await _requireActive();
  }

  @override
  Future<void> register(String name, String email, String password) async {
    await delegate.register(name, email, password);
    await _requireActive();
  }

  @override
  Future<void> retryAccountAccess() async {
    if (_disposed) return;
    _bind(delegate.userId);
    await _settled?.future;
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      delegate.sendPasswordReset(email);
  @override
  Future<void> signOut() => delegate.signOut();

  @override
  bool get canChangePassword =>
      delegate is PasswordService &&
      (delegate as PasswordService).canChangePassword;
  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _requireActive();
    if (!canChangePassword) {
      throw const AuthFailure('Tài khoản không sử dụng mật khẩu Bếp Xinh.');
    }
    await (delegate as PasswordService).changePassword(
      currentPassword,
      newPassword,
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    delegate.sessionChanges.removeListener(_sync);
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    if (_settled case final pending? when !pending.isCompleted) {
      pending.complete(const AccountAccess(AccountAccessStatus.signedOut));
    }
    _changes.dispose();
  }
}
