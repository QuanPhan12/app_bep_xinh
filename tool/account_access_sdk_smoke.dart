import 'dart:async';
import 'dart:js_interop';

import 'package:app_bep_xinh/app.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/services/firestore_user_store.dart';
import 'package:app_bep_xinh/features/auth/models/account_access.dart';
import 'package:app_bep_xinh/features/auth/screens/account_access_screen.dart';
import 'package:app_bep_xinh/features/auth/services/account_guard_auth_service.dart';
import 'package:app_bep_xinh/features/auth/services/auth_service.dart';
import 'package:app_bep_xinh/features/auth/services/firebase_auth_service.dart';
import 'package:app_bep_xinh/features/auth/services/firestore_account_access_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

@JS('firebaseSmokeResult')
external set smokeResult(JSString value);

Future<void> waitFor(
  AccountGuardAuthService guard,
  AccountAccessStatus status,
) async {
  if (guard.accountAccess.status == status) return;
  final done = Completer<void>();
  void listener() {
    if (guard.accountAccess.status == status && !done.isCompleted) {
      done.complete();
    }
  }

  guard.sessionChanges.addListener(listener);
  try {
    await done.future.timeout(const Duration(seconds: 20));
  } finally {
    guard.sessionChanges.removeListener(listener);
  }
}

bool hasAccessScreen() {
  bool found = false;
  void visit(Element e) {
    if (e.widget is AccountAccessScreen) found = true;
    e.visitChildElements(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildElements(visit);
  return found;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  smokeResult = 'running'.toJS;
  var checks = 0;
  void check(bool value, String label) {
    if (!value) throw StateError(label);
    checks++;
  }

  try {
    // Test entry point không nhận cấu hình project thật hoặc credentials người dùng.
    final app = await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'demo-key',
        appId: '1:123456789:web:abcdef',
        messagingSenderId: '123456789',
        projectId: 'demo-bepxinh',
      ),
    );
    final sdkAuth = FirebaseAuth.instanceFor(app: app),
        db = FirebaseFirestore.instanceFor(app: app);
    await sdkAuth.useAuthEmulator('127.0.0.1', 9099);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8080);
    final firebaseAuth = FirebaseAuthService(
      sdkAuth,
      prepareUser: (user) async {
        await FirestoreUserStore(
          firestore: db,
          auth: sdkAuth,
          uid: user.uid,
        ).ensureAccount();
      },
    );
    final source = FirestoreAccountAccessSource(db);
    final guard = AccountGuardAuthService(
      delegate: firebaseAuth,
      source: source,
    );
    final email = 'guard-${DateTime.now().microsecondsSinceEpoch}@example.test';
    await guard.register('Guard test', email, 'EmulatorOnly123!');
    final uid = guard.userId!;
    check(
      guard.accountAccess.status == AccountAccessStatus.active,
      'Registration confirmed by server',
    );
    runApp(AppBepXinh(authService: guard));
    await Future<void>.delayed(const Duration(seconds: 1));
    check(!hasAccessScreen(), 'Active account opens normal app');
    await db.disableNetwork();
    await waitFor(guard, AccountAccessStatus.checking);
    check(
      guard.userId == null,
      'Cached active document cannot grant access offline',
    );
    await db.enableNetwork();
    await waitFor(guard, AccountAccessStatus.active);
    check(guard.userId == uid, 'Server reconnect restores access');
    smokeResult = 'ACCOUNT_LOCK:$uid'.toJS;
    await waitFor(guard, AccountAccessStatus.locked);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    check(
      guard.userId == null && hasAccessScreen(),
      'Live lock removes app screens',
    );
    check(
      guard.accountAccess.message == 'SDK lock test',
      'Lock reason read from Firestore',
    );
    check(
      Uri.parse(authRedirect(guard, Uri.parse('/home'))!).path ==
          '/account-access',
      'Home deep link blocked',
    );
    await guard.signOut();
    var denied = false;
    try {
      await guard.signIn(email, 'EmulatorOnly123!');
    } on AuthFailure {
      denied = true;
    }
    check(
      denied &&
          guard.userId == null &&
          guard.accountAccess.status == AccountAccessStatus.locked,
      'Correct credentials cannot reopen locked account',
    );
    final restored = AccountGuardAuthService(
      delegate: firebaseAuth,
      source: source,
    );
    check(
      restored.userId == null,
      'Restored Firebase Auth UID initially hidden',
    );
    await waitFor(restored, AccountAccessStatus.locked);
    check(restored.userId == null, 'Restored session checks actual lock');
    restored.dispose();
    smokeResult = 'ACCOUNT_UNLOCK:$uid'.toJS;
    await waitFor(guard, AccountAccessStatus.active);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    check(
      guard.userId == uid && !hasAccessScreen(),
      'Admin unlock restores app without relaunch',
    );
    smokeResult =
        'PASS: $checks Flutter account-access SDK/UI checks (demo emulator only)'
            .toJS;
  } catch (error, stack) {
    debugPrintStack(stackTrace: stack);
    smokeResult = 'FAIL: $error'.toJS;
    runApp(
      MaterialApp(
        home: Scaffold(body: Text('Account guard smoke failed: $error')),
      ),
    );
  }
}
