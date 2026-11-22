import 'dart:async';

import 'package:app_bep_xinh/features/auth/services/auth_service.dart';
import 'package:app_bep_xinh/features/auth/services/firebase_auth_service.dart';
import 'package:app_bep_xinh/features/auth/services/google_auth_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockCredential extends Mock implements UserCredential {}

class MockGoogleClient extends Mock implements GoogleAuthClient {}

class MockUserInfo extends Mock implements UserInfo {}

void main() {
  setUpAll(
    () => registerFallbackValue(
      EmailAuthProvider.credential(
        email: 'test@example.test',
        password: 'test',
      ),
    ),
  );
  late MockAuth auth;
  late MockUser user;
  late MockCredential credential;
  late StreamController<User?> changes;
  late FirebaseAuthService service;
  User? current;

  setUp(() {
    auth = MockAuth();
    user = MockUser();
    credential = MockCredential();
    changes = StreamController<User?>.broadcast(sync: true);
    current = null;
    when(() => auth.currentUser).thenAnswer((_) => current);
    when(() => auth.authStateChanges()).thenAnswer((_) => changes.stream);
    when(() => user.uid).thenReturn('account-a');
    when(() => credential.user).thenReturn(user);
    service = FirebaseAuthService(auth, prepareUser: (_) async {});
  });
  tearDown(() async {
    service.dispose();
    await changes.close();
  });

  test('Password change reauthenticates before updating and rejects wrong current password', () async {
    current = user;
    final provider = MockUserInfo();
    when(() => provider.providerId).thenReturn('password');
    when(() => user.providerData).thenReturn([provider]);
    when(() => user.email).thenReturn('test@example.test');
    when(() => user.reauthenticateWithCredential(any()))
        .thenAnswer((_) async => credential);
    when(() => user.updatePassword('new-123')).thenAnswer((_) async {});
    await service.changePassword('old-123', 'new-123');
    verifyInOrder([
      () => user.reauthenticateWithCredential(any()),
      () => user.updatePassword('new-123'),
    ]);
    when(() => user.reauthenticateWithCredential(any()))
        .thenThrow(FirebaseAuthException(code: 'wrong-password'));
    await expectLater(
      service.changePassword('wrong', 'another-123'),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => user.updatePassword('another-123'));
  });
  test(
    'Password change stops if session changes during reauthentication',
    () async {
      current = user;
      final provider = MockUserInfo();
      when(() => provider.providerId).thenReturn('password');
      when(() => user.providerData).thenReturn([provider]);
      when(() => user.email).thenReturn('test@example.test');
      when(() => user.reauthenticateWithCredential(any()))
          .thenAnswer((_) async {
            current = null;
            return credential;
          });
      await expectLater(
        service.changePassword('old-123', 'new-123'),
        throwsA(isA<AuthFailure>()),
      );
      verifyNever(() => user.updatePassword(any()));
    },
  );
  test('External-provider account cannot change a Firebase password', () async {
    current = user;
    final provider = MockUserInfo();
    when(() => provider.providerId).thenReturn('google.com');
    when(() => user.providerData).thenReturn([provider]);
    expect(service.canChangePassword, isFalse);
    await expectLater(
      service.changePassword('old-123', 'new-123'),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => user.reauthenticateWithCredential(any()));
  });

  test(
    'Google session waits for profile preparation before publishing UID',
    () async {
      final google = MockGoogleClient(), saved = Completer<void>();
      service.dispose();
      service = FirebaseAuthService(
        auth,
        googleAuth: google,
        prepareUser: (_) => saved.future,
      );
      when(() => google.signIn(auth)).thenAnswer((_) async {
        current = user;
        changes.add(user);
        return credential;
      });
      final login = service.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);
      expect(service.userId, isNull);
      saved.complete();
      await login;
      expect(service.userId, 'account-a');
    },
  );

  test(
    'Google cancellation is preserved and popup failures are translated',
    () async {
      final google = MockGoogleClient();
      service.dispose();
      service = FirebaseAuthService(
        auth,
        googleAuth: google,
        prepareUser: (_) async {},
      );
      when(() => google.signIn(auth)).thenThrow(const AuthCancelled());
      await expectLater(
        service.signInWithGoogle(),
        throwsA(isA<AuthCancelled>()),
      );
      when(() => google.signIn(auth))
          .thenThrow(FirebaseAuthException(code: 'popup-closed-by-user'));
      await expectLater(
        service.signInWithGoogle(),
        throwsA(isA<AuthCancelled>()),
      );
      when(() => google.signIn(auth))
          .thenThrow(FirebaseAuthException(code: 'popup-blocked'));
      await expectLater(
        service.signInWithGoogle(),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            contains('popup'),
          ),
        ),
      );
      expect(service.userId, isNull);
    },
  );

  test(
    'sign-in publishes actual UID after SDK success and preserves password',
    () async {
      final pending = Completer<UserCredential>();
      when(
        () => auth.signInWithEmailAndPassword(
          email: 'cook@example.test',
          password: ' secret ',
        ),
      ).thenAnswer((_) => pending.future);
      final task = service.signIn(' cook@example.test ', ' secret ');
      current = user;
      changes.add(user);
      expect(service.userId, isNull);
      pending.complete(credential);
      await task;
      expect(service.userId, 'account-a');
    },
  );

  test(
    'registration publishes session only after display name is saved',
    () async {
      final nameSaved = Completer<void>();
      when(
        () => auth.createUserWithEmailAndPassword(
          email: 'cook@example.test',
          password: 'secret',
        ),
      ).thenAnswer((_) async {
        current = user;
        changes.add(user);
        return credential;
      });
      when(() => user.updateDisplayName('Đầu bếp'))
          .thenAnswer((_) => nameSaved.future);
      final task = service.register(' Đầu bếp ', 'cook@example.test', 'secret');
      await Future<void>.delayed(Duration.zero);
      expect(service.userId, isNull);
      nameSaved.complete();
      await task;
      expect(service.userId, 'account-a');
    },
  );

  test(
    'wrong credentials never publish a session and hide SDK details',
    () async {
      when(
        () => auth.signInWithEmailAndPassword(
          email: 'cook@example.test',
          password: 'secret',
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'invalid-credential',
          message: 'internal details',
        ),
      );
      await expectLater(
        service.signIn('cook@example.test', 'secret'),
        throwsA(
          isA<AuthFailure>().having(
            (error) => error.message,
            'message',
            'Email hoặc mật khẩu không đúng.',
          ),
        ),
      );
      expect(service.userId, isNull);
    },
  );

  test('reset hides nonexistent email but reports network failure', () async {
    when(() => auth.sendPasswordResetEmail(email: 'cook@example.test'))
        .thenThrow(FirebaseAuthException(code: 'user-not-found'));
    await service.sendPasswordReset('cook@example.test');
    when(() => auth.sendPasswordResetEmail(email: 'cook@example.test'))
        .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await expectLater(
      service.sendPasswordReset('cook@example.test'),
      throwsA(isA<AuthFailure>()),
    );
  });

  test('sign-out and external revocation notify session listeners', () async {
    var notices = 0;
    service.sessionChanges.addListener(() => notices++);
    current = user;
    changes.add(user);
    expect(service.userId, 'account-a');
    when(() => auth.signOut()).thenAnswer((_) async {
      current = null;
      changes.add(null);
    });
    await service.signOut();
    expect(service.userId, isNull);
    expect(notices, 2);
  });

  test(
    'registration waits for the Firestore write before publishing a session',
    () async {
      final saved = Completer<void>();
      var prepared = 0;
      service.dispose();
      service = FirebaseAuthService(
        auth,
        prepareUser: (account) async {
          expect(account.uid, 'account-a');
          prepared++;
          await saved.future;
        },
      );
      when(
        () => auth.createUserWithEmailAndPassword(
          email: 'cook@example.test',
          password: 'secret',
        ),
      ).thenAnswer((_) async {
        current = user;
        changes.add(user);
        return credential;
      });
      when(() => user.updateDisplayName('Đầu bếp')).thenAnswer((_) async {});
      final task = service.register('Đầu bếp', 'cook@example.test', 'secret');
      await Future<void>.delayed(Duration.zero);
      expect(prepared, 1);
      expect(service.userId, isNull);
      saved.complete();
      await task;
      expect(service.userId, 'account-a');
    },
  );

  test(
    'partial registration signs out and later sign-in retries provisioning',
    () async {
      var prepared = 0;
      service.dispose();
      service = FirebaseAuthService(
        auth,
        prepareUser: (_) async {
          if (++prepared == 1) throw StateError('Firestore unavailable');
        },
      );
      when(
        () => auth.createUserWithEmailAndPassword(
          email: 'cook@example.test',
          password: 'secret',
        ),
      ).thenAnswer((_) async {
        current = user;
        changes.add(user);
        return credential;
      });
      when(() => user.updateDisplayName('Đầu bếp')).thenAnswer((_) async {});
      when(() => auth.signOut()).thenAnswer((_) async {
        current = null;
        changes.add(null);
      });
      await expectLater(
        service.register('Đầu bếp', 'cook@example.test', 'secret'),
        throwsA(isA<AuthFailure>()),
      );
      expect(service.userId, isNull);
      verify(() => auth.signOut()).called(1);
      when(
        () => auth.signInWithEmailAndPassword(
          email: 'cook@example.test',
          password: 'secret',
        ),
      ).thenAnswer((_) async {
        current = user;
        changes.add(user);
        return credential;
      });
      await service.signIn('cook@example.test', 'secret');
      expect(prepared, 2);
      expect(service.userId, 'account-a');
      verify(
        () => auth.createUserWithEmailAndPassword(
          email: 'cook@example.test',
          password: 'secret',
        ),
      ).called(1);
    },
  );

  test('failed display-name write or sign-out never publishes incomplete registration', () async {
    when(
      () => auth.createUserWithEmailAndPassword(
        email: 'cook@example.test',
        password: 'secret',
      ),
    ).thenAnswer((_) async {
      current = user;
      changes.add(user);
      return credential;
    });
    when(() => user.updateDisplayName('Đầu bếp'))
        .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    when(() => auth.signOut()).thenThrow(StateError('SDK signout failed'));
    await expectLater(
      service.register('Đầu bếp', 'cook@example.test', 'secret'),
      throwsA(isA<AuthFailure>()),
    );
    changes.add(user);
    expect(service.userId, isNull);
  });
}
