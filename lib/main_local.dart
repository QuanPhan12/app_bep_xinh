import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/services/firestore_user_store.dart';
import 'core/tap/tap.dart';
import 'core/router/app_router.dart';

import 'package:go_router/go_router.dart';

import 'features/auth/services/firebase_auth_service.dart';
import 'features/auth/services/account_guard_auth_service.dart';
import 'features/auth/services/firestore_account_access_source.dart';

/// Entry local dùng project demo cố định, xác thực thật qua emulator; không bỏ guard.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kReleaseMode || !kIsWeb) {
    throw StateError(
      'main_local chỉ chạy Flutter web debug với demo emulator.',
    );
  }
  const base = String.fromEnvironment('AI_API_BASE_URL');
  final url = Uri.tryParse(base);
  if (url == null ||
      url.scheme != 'http' ||
      !['127.0.0.1', 'localhost'].contains(url.host) ||
      !url.path.contains('/demo-bepxinh/')) {
    throw StateError(
      'Truyền AI_API_BASE_URL trỏ tới Functions demo emulator theo docs/AI_CHAT.md.',
    );
  }
  usePathUrlStrategy();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'demo-key',
      appId: '1:123456789:web:abcdef',
      messagingSenderId: '123456789',
      projectId: 'demo-bepxinh',
      authDomain: 'demo-bepxinh.firebaseapp.com',
    ),
  );
  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
  await FirebaseAuth.instance.authStateChanges().first;
  final sdk = FirebaseAuthService(
    FirebaseAuth.instance,
    prepareUser: (user) async {
      await FirestoreUserStore(
        firestore: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
        uid: user.uid,
      ).ensureAccount();
    },
  );
  final auth = AccountGuardAuthService(
    delegate: sdk,
    source: FirestoreAccountAccessSource(FirebaseFirestore.instance),
  );
  AppTapHandler.instance.configureAuth(
    isAuthenticated: () => auth.userId != null,
    onUnauthenticated: (context, _) {
      context.push(PathRouter.loginScreen);
    },
  );
  runApp(AppBepXinh(authService: auth));
}
