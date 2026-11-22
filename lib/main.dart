import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'features/auth/services/firebase_auth_service.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/services/account_guard_auth_service.dart';
import 'features/auth/services/firestore_account_access_source.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/services/firestore_user_store.dart';

import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/app.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Be Vietnam Pro',
    ], await rootBundle.loadString('assets/fonts/be_vietnam_pro/OFL.txt'));
  });

  // Cấu hình kiểm tra tập trung cho hệ thống onTap
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  const emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
  if (emulatorHost.isNotEmpty) {
    if (kReleaseMode) {
      throw StateError('Firebase emulators require a debug build');
    }
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
  }
  // Chờ SDK khôi phục phiên trước khi router quyết định màn hình đầu tiên.
  await FirebaseAuth.instance.authStateChanges().first;
  final firebaseAuth = FirebaseAuthService(   
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
    delegate: firebaseAuth,
    source: FirestoreAccountAccessSource(FirebaseFirestore.instance),
  );
  _setupTapInterceptors(auth);

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => AppBepXinh(authService: auth),
    ),
  );
}

void _setupTapInterceptors(AuthService auth) {
  // 1. Cấu hình kiểm tra đăng nhập tập trung
  AppTapHandler.instance.configureAuth(
    isAuthenticated: () => auth.userId != null,
    onUnauthenticated: (context, config) {
      context.push(PathRouter.loginScreen);
      AppMessenger.showWarning(
        context,
        'Hành động "${config.actionName ?? 'này'}" yêu cầu đăng nhập!',
        title: 'Chưa đăng nhập',
      );
    },
  );

  // 2. Cấu hình ghi nhận Analytics / Logging tập trung
  AppTapHandler.instance.configureAnalytics(
    onTrack: (actionName, params) {
      // TODO: Gửi sự kiện sang FirebaseAnalytics.instance.logEvent(name: actionName, parameters: params)
      debugPrint(
        '🚀 [Analytics Tracked] Action: $actionName | Params: $params',
      );
    },
  );
}
