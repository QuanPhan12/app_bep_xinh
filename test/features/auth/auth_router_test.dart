import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/features/auth/services/auth_service.dart';
import 'package:app_bep_xinh/features/auth/screens/login/login_screen.dart';
import 'package:app_bep_xinh/features/profile/screens/profile_screen.dart';
import 'package:app_bep_xinh/features/profile/services/profile_service.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../../support/auth_fake.dart';
import '../../support/profile_fakes.dart';
import '../../support/recipe_detail_fakes.dart';
import '../../support/test_text_styles.dart';

void main() {
  setUpAll(configureTestTextStyles);
  late StubAuthService auth;
  setUp(() => auth = StubAuthService());
  tearDown(() => auth.dispose());

  testWidgets(
    'real router resumes private deep link and removes profile on sign-out',
    (tester) async {
      final router = createAppRouter(auth: auth);
      router.go('/profile');
      final profile = StubProfileService();
      final favorites = StubRecipeFavoritesService();
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthService>.value(value: auth),
            RepositoryProvider<ProfileService>.value(value: profile),
            RepositoryProvider<RecipeFavoritesService>.value(value: favorites),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      auth.setUser('account-a');
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/profile');
      await auth.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ProfileScreen, skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await profile.dispose();
      await favorites.dispose();
    },
  );

  test('guest can browse but private deep links require authentication', () {
    for (final path in [
      '/home',
      '/recipe/tofu',
      '/recipes/search',
      '/users/chef',
    ]) {
      expect(authRedirect(auth, Uri.parse(path)), isNull);
    }
    for (final path in [
      '/profile',
      '/profile/edit',
      '/settings',
      '/fridge',
      '/cart',
      '/recipes/new',
    ]) {
      final target = Uri.parse(authRedirect(auth, Uri.parse(path))!);
      expect(target.path, '/login');
      expect(target.queryParameters['from'], path);
    }
  });

  test(
    'restored session returns to intended page and rejects external redirects',
    () {
      auth.id = 'account-a';
      expect(
        authRedirect(auth, Uri.parse('/login?from=%2Fprofile%2Fedit')),
        '/profile/edit',
      );
      expect(
        authRedirect(auth, Uri.parse('/login?from=https%3A%2F%2Fevil.test')),
        '/home',
      );
      expect(
        authRedirect(auth, Uri.parse('/login?from=%2F%2Fevil.test')),
        '/home',
      );
      expect(authRedirect(auth, Uri.parse('/login?from=%2Fregister')), '/home');
      expect(authRedirect(auth, Uri.parse('/profile')), isNull);
    },
  );
}
