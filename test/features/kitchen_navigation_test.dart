import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/features/recipe_sharing/services/recipe_sharing_service.dart';
import 'package:app_bep_xinh/features/recipe_detail/screens/recipe_detail_screen.dart';
import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../support/auth_fake.dart';
import '../support/recipe_detail_fakes.dart';
import '../support/test_text_styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureTestTextStyles);
  test('shared HTTPS URLs encode one recipe segment and preserve origin', () {
    final sharing = RecipeSharingService(
      publicAppUrl: 'https://recipes.example.test:8443',
    );
    final link = sharing.link('cá hồi 50%');
    expect(link.scheme, 'https');
    expect(link.host, 'recipes.example.test');
    expect(link.port, 8443);
    expect(link.pathSegments, ['recipe', 'cá hồi 50%']);
    expect(link.fragment, isEmpty);
    expect(() => sharing.link('a/b'), throwsFormatException);
    expect(
      () => RecipeSharingService(publicAppUrl: 'http://example.test'),
      throwsArgumentError,
    );
    expect(
      () => RecipeSharingService(publicAppUrl: 'https://user@example.test'),
      throwsArgumentError,
    );
  });
  test('kitchen private links require login; public review and recipe links do not', () {
    final auth = StubAuthService();
    addTearDown(auth.dispose);
    for (final path in [
      '/kitchen',
      '/kitchen/meal-plan',
      '/kitchen/pantry',
      '/kitchen/collections',
      '/kitchen/journal',
      '/kitchen/timers',
      '/kitchen/offline',
      '/kitchen/following/feed',
    ]) {
      final redirect = Uri.parse(authRedirect(auth, Uri.parse(path))!);
      expect(redirect.path, '/login');
      expect(redirect.queryParameters['from'], path);
    }
    for (final path in ['/recipe/r_a', '/recipe/r_a/reviews']) {
      expect(authRedirect(auth, Uri.parse(path)), isNull);
    }
    auth.setUser('alice');
    expect(
      authRedirect(auth, Uri.parse('/login?from=%2Fkitchen%2Fmeal-plan')),
      '/kitchen/meal-plan',
    );
  });
  testWidgets(
    'platform direct recipe URL takes precedence over default login',
    (tester) async {
      tester.binding.platformDispatcher.defaultRouteNameTestValue =
          '/recipe/r_a';
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );
      final auth = StubAuthService();
      addTearDown(auth.dispose);
      final router = createAppRouter(auth: auth);
      addTearDown(router.dispose);
      expect(router.routeInformationProvider.value.uri.path, '/recipe/r_a');
    },
  );

  testWidgets(
    'shared HTTPS link opens the requested recipe on cold and warm launch',
    (tester) async {
      final sharing = RecipeSharingService();
      tester.binding.platformDispatcher.defaultRouteNameTestValue = sharing
          .link('bo_ne_tieu_den')
          .toString();
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );
      final auth = StubAuthService();
      final favorites = StubRecipeFavoritesService();
      final details = StubRecipeDetailService();
      final router = createAppRouter(auth: auth);
      addTearDown(auth.dispose);
      addTearDown(favorites.dispose);
      addTearDown(router.dispose);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RecipeDetailService>.value(value: details),
            RepositoryProvider<RecipeFavoritesService>.value(value: favorites),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RecipeDetailScreen>(find.byType(RecipeDetailScreen))
            .recipeId,
        'bo_ne_tieu_den',
      );
      expect(auth.userId, isNull);
      await tester.binding.handlePushRoute(
        sharing.link('ca_hoi_ap_chao').toString(),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RecipeDetailScreen>(find.byType(RecipeDetailScreen))
            .recipeId,
        'ca_hoi_ap_chao',
      );
      expect(details.calls, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
