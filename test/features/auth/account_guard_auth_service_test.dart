import 'dart:async';

import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/features/auth/models/account_access.dart';
import 'package:app_bep_xinh/features/auth/cubits/login/login.dart';
import 'package:app_bep_xinh/features/auth/screens/login/login_screen.dart';
import 'package:app_bep_xinh/features/auth/widgets/login_form.dart';
import 'package:app_bep_xinh/features/auth/screens/account_access_screen.dart';
import 'package:app_bep_xinh/features/auth/services/account_guard_auth_service.dart';
import 'package:app_bep_xinh/features/auth/services/auth_service.dart';
import 'package:app_bep_xinh/features/profile/screens/profile_screen.dart';
import 'package:app_bep_xinh/features/profile/services/profile_service.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_fake.dart';
import '../../support/profile_fakes.dart';
import '../../support/recipe_detail_fakes.dart';
import '../../support/test_text_styles.dart';

class FakeAccessSource implements AccountAccessSource {
  final controllers = <String, StreamController<AccountAccess>>{};
  int subscriptions = 0;
  StreamController<AccountAccess> controller(String uid) =>
      controllers.putIfAbsent(
        uid,
        () => StreamController<AccountAccess>.broadcast(sync: true),
      );
  @override
  Stream<AccountAccess> watch(String uid) {
    subscriptions++;
    return controller(uid).stream;
  }

  void emit(String uid, AccountAccessStatus status, {String? message}) =>
      controller(uid).add(AccountAccess(status, message: message));
  Future<void> dispose() async {
    for (final c in controllers.values) {
      await c.close();
    }
  }
}

void main() {
  setUpAll(configureTestTextStyles);
  late StubAuthService delegate;
  late FakeAccessSource source;
  late AccountGuardAuthService guard;
  setUp(() {
    delegate = StubAuthService();
    source = FakeAccessSource();
    guard = AccountGuardAuthService(delegate: delegate, source: source);
  });
  tearDown(() async {
    guard.dispose();
    delegate.dispose();
    await source.dispose();
  });

  test(
    'Google login still requires an active account and cannot bypass a lock',
    () async {
      delegate.operation = () async {
        delegate.setUser('google-user');
      };
      final login = guard.signInWithGoogle();
      final denied = expectLater(login, throwsA(isA<AuthFailure>()));
      await Future<void>.delayed(Duration.zero);
      expect(guard.userId, isNull);
      source.emit('google-user', AccountAccessStatus.locked);
      await denied;
      expect(guard.userId, isNull);
      expect(delegate.googleSignInCalls, 1);
    },
  );

  test('restored Auth UID stays hidden until profile is confirmed; lock/unlock is realtime', () {
    delegate.setUser('a');
    expect(guard.userId, isNull);
    expect(guard.accountAccess.status, AccountAccessStatus.checking);
    source.emit('a', AccountAccessStatus.active);
    expect(guard.userId, 'a');
    source.emit('a', AccountAccessStatus.locked, message: 'Vi phạm nội dung');
    expect(guard.userId, isNull);
    expect(guard.accountAccess.message, 'Vi phạm nội dung');
    for (final path in [
      '/home',
      '/recipe/tofu',
      '/profile',
      '/messages',
      '/login',
    ]) {
      expect(
        Uri.parse(authRedirect(guard, Uri.parse(path))!).path,
        '/account-access',
      );
    }
    source.emit('a', AccountAccessStatus.active);
    expect(guard.userId, 'a');
  });

  test('cold start does not publish a previously saved Auth session', () {
    guard.dispose();
    delegate.setUser('saved');
    guard = AccountGuardAuthService(delegate: delegate, source: source);
    expect(guard.userId, isNull);
    expect(guard.accountAccess.status, AccountAccessStatus.checking);
    source.emit('saved', AccountAccessStatus.locked);
    expect(guard.userId, isNull);
    expect(guard.accountAccess.status, AccountAccessStatus.locked);
  });

  test(
    'auth forms stay visible during checks but locked accounts are redirected',
    () {
      delegate.setUser('a');
      for (final path in [
        '/login?from=%2Fprofile',
        '/register',
        '/forgot-password',
      ]) {
        expect(authRedirect(guard, Uri.parse(path)), isNull);
      }
      expect(guard.userId, isNull);
      expect(
        Uri.parse(authRedirect(guard, Uri.parse('/home'))!).path,
        '/account-access',
      );
      source.emit('a', AccountAccessStatus.locked);
      expect(
        Uri.parse(authRedirect(guard, Uri.parse('/login'))!).path,
        '/account-access',
      );
    },
  );

  testWidgets(
    'login stays loading until verified then opens intended screen directly',
    (tester) async {
      delegate.operation = () async {
        delegate.setUser('a');
      };
      final router = createAppRouter(auth: guard)..go('/login?from=%2Fprofile');
      final profile = StubProfileService(),
          favorites = StubRecipeFavoritesService();
      final visited = <String>[];
      router.routeInformationProvider.addListener(() {
        visited.add(router.routeInformationProvider.value.uri.path);
      });
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthService>.value(value: guard),
            RepositoryProvider<ProfileService>.value(value: profile),
            RepositoryProvider<RecipeFavoritesService>.value(value: favorites),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      final cubit = tester.element(find.byType(LoginForm)).read<LoginCubit>();
      cubit.emailChanged('cook@example.test');
      cubit.passwordChanged('secret-123');
      final login = cubit.submitLogin();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(cubit.state.status, LoginStatus.loading);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AccountAccessScreen), findsNothing);
      expect(guard.userId, isNull);
      source.emit('a', AccountAccessStatus.active);
      await login;
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(visited, isNot(contains('/account-access')));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await profile.dispose();
      await favorites.dispose();
    },
  );

  test(
    'correct password does not report login success for a locked account',
    () async {
      delegate.operation = () async {
        delegate.setUser('a');
      };
      final login = guard.signIn('cook@example.test', 'secret');
      final failure = expectLater(login, throwsA(isA<AuthFailure>()));
      await Future<void>.delayed(Duration.zero);
      source.emit('a', AccountAccessStatus.locked);
      await failure;
      expect(guard.userId, isNull);
      expect(delegate.signInCalls, 1);
    },
  );

  test(
    'registration waits for account validation before publishing UID',
    () async {
      delegate.operation = () async {
        delegate.setUser('new');
      };
      final registration = guard.register(
        'Cook',
        'cook@example.test',
        'secret',
      );
      await Future<void>.delayed(Duration.zero);
      expect(guard.userId, isNull);
      source.emit('new', AccountAccessStatus.active);
      await registration;
      expect(guard.userId, 'new');
    },
  );

  test('listener failure blocks access; retry starts a new listener', () async {
    delegate.setUser('a');
    source.emit('a', AccountAccessStatus.active);
    source.controller('a').addError(StateError('permission-denied'));
    expect(guard.userId, isNull);
    expect(guard.accountAccess.status, AccountAccessStatus.unavailable);
    final attempts = source.subscriptions;
    final retry = guard.retryAccountAccess();
    expect(source.subscriptions, attempts + 1);
    expect(guard.accountAccess.status, AccountAccessStatus.checking);
    source.emit('a', AccountAccessStatus.active);
    await retry;
    expect(guard.userId, 'a');
  });

  test('late events from a previous UID cannot unlock the next session', () {
    delegate.setUser('a');
    source.emit('a', AccountAccessStatus.active);
    delegate.setUser('b');
    source.emit('a', AccountAccessStatus.active);
    expect(guard.userId, isNull);
    source.emit('b', AccountAccessStatus.locked);
    source.emit('a', AccountAccessStatus.active);
    expect(guard.userId, isNull);
    expect(guard.accountAccess.status, AccountAccessStatus.locked);
  });

  testWidgets(
    'verification timeout offers recovery and does not allow cached access',
    (tester) async {
      delegate.setUser('a');
      await tester.pump(const Duration(seconds: 16));
      expect(guard.accountAccess.status, AccountAccessStatus.unavailable);
      expect(guard.userId, isNull);
      source.emit('a', AccountAccessStatus.active);
      expect(guard.userId, 'a');
      source.emit('a', AccountAccessStatus.checking);
      expect(guard.userId, isNull);
      await tester.pump(const Duration(seconds: 16));
      expect(guard.accountAccess.status, AccountAccessStatus.unavailable);
    },
  );

  test(
    'sign-out cancels validation; late callbacks cannot restore UID',
    () async {
      delegate.setUser('a');
      await guard.signOut();
      source.emit('a', AccountAccessStatus.active);
      expect(guard.userId, isNull);
      expect(guard.accountAccess.status, AccountAccessStatus.signedOut);
      expect(authRedirect(guard, Uri.parse('/account-access')), '/login');
    },
  );

  testWidgets(
    'real router removes private screens immediately after a live lock',
    (tester) async {
      delegate.setUser('a');
      final router = createAppRouter(auth: guard)..go('/profile');
      final profile = StubProfileService(),
          favorites = StubRecipeFavoritesService();
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthService>.value(value: guard),
            RepositoryProvider<ProfileService>.value(value: profile),
            RepositoryProvider<RecipeFavoritesService>.value(value: favorites),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AccountAccessScreen), findsOneWidget);
      expect(find.byType(ProfileScreen, skipOffstage: false), findsNothing);
      source.emit('a', AccountAccessStatus.active);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      source.emit('a', AccountAccessStatus.locked, message: 'Vi phạm quy định');
      await tester.pumpAndSettle();
      expect(find.text('Tài khoản bị khóa'), findsOneWidget);
      expect(find.text('Lý do: Vi phạm quy định'), findsOneWidget);
      expect(find.byType(ProfileScreen, skipOffstage: false), findsNothing);
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.byType(AccountAccessScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await profile.dispose();
      await favorites.dispose();
    },
  );
}
