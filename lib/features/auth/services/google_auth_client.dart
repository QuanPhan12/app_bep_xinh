import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../firebase_options.dart';
import 'auth_service.dart';

abstract interface class GoogleAuthClient {
  Future<UserCredential> signIn(FirebaseAuth auth);
  Future<void> signOut();
}

class PlatformGoogleAuthClient implements GoogleAuthClient {
  final GoogleSignIn native;
  final bool isWeb;
  final TargetPlatform platform;
  Future<void>? _initialization;

  PlatformGoogleAuthClient({
    GoogleSignIn? native,
    bool? isWeb,
    TargetPlatform? platform,
  }) : native = native ?? GoogleSignIn.instance,
       isWeb = isWeb ?? kIsWeb,
       platform = platform ?? defaultTargetPlatform;

  Future<void> _initialize() async {
    try {
      await (_initialization ??= native.initialize(
        clientId: platform == TargetPlatform.iOS
            ? DefaultFirebaseOptions.ios.iosClientId
            : null,
        // Web OAuth client của đúng project, cũng có trong google-services.json.
        serverClientId: '955775168150-mt01o910npu5rf06ckbn3hcqb3c5qnlg.apps.googleusercontent.com',
      ));
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  @override
  Future<UserCredential> signIn(FirebaseAuth auth) async {
    if (isWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      return auth.signInWithPopup(provider);
    }
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      throw const AuthFailure(
        'Đăng nhập Google chưa được hỗ trợ trên nền tảng này.',
      );
    }
    try {
      await _initialize();
      final account = await native.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw const AuthFailure(
          'Không nhận được xác thực từ Google. Vui lòng thử lại.',
        );
      }
      return await auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: token),
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelled();
      }
      throw const AuthFailure(
        'Không thể đăng nhập Google lúc này. Vui lòng thử lại.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (!isWeb && _initialization != null) await native.signOut();
  }
}
