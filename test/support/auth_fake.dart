import 'package:app_bep_xinh/features/auth/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';

void configureAuthenticatedTaps() {
  AppTapHandler.instance.configureAuth(
    isAuthenticated: () => true,
    onUnauthenticated: (_, _) {},
  );
}

class StubAuthService implements AuthService {
  final _sessionChanges = ValueNotifier<String?>(null);
  @override
  Listenable get sessionChanges => _sessionChanges;
  void dispose() => _sessionChanges.dispose();
  String? get id => _sessionChanges.value;
  set id(String? value) => _sessionChanges.value = value;
  int signInCalls = 0;
  int googleSignInCalls = 0;
  int registerCalls = 0;
  int resetCalls = 0;
  int signOutCalls = 0;
  String? password;
  String? email;
  String? name;
  Future<void> Function()? operation;

  @override
  String? get userId => id;

  void setUser(String? value) {
    id = value;
  }

  @override
  Future<void> signIn(String email, String password) async {
    signInCalls++;
    this.email = email;
    this.password = password;
    await operation?.call();
  }

  @override
  Future<void> signInWithGoogle() async {
    googleSignInCalls++;
    await operation?.call();
  }

  @override
  Future<void> register(String name, String email, String password) async {
    registerCalls++;
    this.name = name;
    this.email = email;
    this.password = password;
    await operation?.call();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    resetCalls++;
    this.email = email;
    await operation?.call();
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    await operation?.call();
    setUser(null);
  }
}
