import 'package:app_bep_xinh/features/auth/services/auth_service.dart';
import 'package:app_bep_xinh/features/auth/services/google_auth_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends Mock implements FirebaseAuth {}

class _Credential extends Mock implements UserCredential {}

class _Google extends Mock implements GoogleSignIn {}

class _Account extends Mock implements GoogleSignInAccount {}

void main() {
  setUpAll(() {
    registerFallbackValue(GoogleAuthProvider());
    registerFallbackValue(GoogleAuthProvider.credential(idToken: 'test-token'));
  });
  late _Auth auth;
  late _Google google;
  late _Credential result;
  setUp(() {
    auth = _Auth();
    google = _Google();
    result = _Credential();
    when(
      () => google.initialize(
        clientId: any(named: 'clientId'),
        serverClientId: any(named: 'serverClientId'),
      ),
    ).thenAnswer((_) async {});
    when(() => google.signOut()).thenAnswer((_) async {});
  });
  test(
    'Web uses Firebase popup with Google provider and no native plugin',
    () async {
      final client = PlatformGoogleAuthClient(native: google, isWeb: true);
      when(() => auth.signInWithPopup(any())).thenAnswer((_) async => result);
      expect(await client.signIn(auth), same(result));
      final provider =
          verify(() => auth.signInWithPopup(captureAny())).captured.single
              as AuthProvider;
      expect(provider.providerId, 'google.com');
      verifyNever(() => google.authenticate());
    },
  );
  test('Android exchanges Google ID token, initializes once and clears picker session on logout', () async {
    final account = _Account();
    when(() => account.authentication)
        .thenReturn(const GoogleSignInAuthentication(idToken: 'test-token'));
    when(() => google.authenticate()).thenAnswer((_) async => account);
    when(() => auth.signInWithCredential(any()))
        .thenAnswer((_) async => result);
    final client = PlatformGoogleAuthClient(
      native: google,
      isWeb: false,
      platform: TargetPlatform.android,
    );
    await client.signIn(auth);
    await client.signIn(auth);
    await client.signOut();
    verify(
      () => google.initialize(
        clientId: null,
        serverClientId: any(named: 'serverClientId'),
      ),
    ).called(1);
    final credential =
        verify(() => auth.signInWithCredential(captureAny())).captured.first
            as OAuthCredential;
    expect(credential.idToken, 'test-token');
    expect(credential.providerId, 'google.com');
    verify(() => google.signOut()).called(1);
  });
  test('native cancellation does not send a Firebase credential', () async {
    when(() => google.authenticate()).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );
    final client = PlatformGoogleAuthClient(
      native: google,
      isWeb: false,
      platform: TargetPlatform.android,
    );
    await expectLater(client.signIn(auth), throwsA(isA<AuthCancelled>()));
    verifyNever(() => auth.signInWithCredential(any()));
  });
  test('missing Google token fails before Firebase sign-in', () async {
    final account = _Account();
    when(() => account.authentication)
        .thenReturn(const GoogleSignInAuthentication(idToken: null));
    when(() => google.authenticate()).thenAnswer((_) async => account);
    final client = PlatformGoogleAuthClient(
      native: google,
      isWeb: false,
      platform: TargetPlatform.iOS,
    );
    await expectLater(client.signIn(auth), throwsA(isA<AuthFailure>()));
    verifyNever(() => auth.signInWithCredential(any()));
  });
}
