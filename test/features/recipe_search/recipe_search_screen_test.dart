import 'package:app_bep_xinh/core/widgets/app_selection_controls.dart';

import '../../support/auth_fake.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/product/widgets/product_card.dart';
import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';
import 'package:app_bep_xinh/features/recipe_search/cubits/recipe_search_cubit.dart';
import 'package:app_bep_xinh/features/recipe_search/models/recipe_search_request.dart';
import 'package:app_bep_xinh/features/recipe_search/screens/recipe_search_screen.dart';
import 'package:app_bep_xinh/features/recipe_search/services/recipe_search_service.dart';
import 'package:app_bep_xinh/features/recipe_search/widgets/recipe_search_results.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/mock_services.dart';
import '../../support/recipe_detail_fakes.dart';
import '../../support/recipe_search_fakes.dart';
import '../../support/test_text_styles.dart';

void main() {
  setUp(configureAuthenticatedTaps);
  setUpAll(configureTestTextStyles);
  setUp(AppTapHandler.resetLock);
  late StubRecipeFavoritesService favorites;
  late StubRecipeSearchService service;
  setUp(() {
    favorites = StubRecipeFavoritesService();
    final api = fixtureApi();
    service = StubRecipeSearchService()
      ..onSearch = MockRecipeSearchService(
        api,
        MockIngredientCatalogService(api),
        favorites,
      ).search;
  });
  tearDown(() => favorites.dispose());

  Future<GoRouter> open(
    WidgetTester tester, {
    String path = '/recipes/search',
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: appRouter.configuration.routes,
      initialLocation: path,
    );
    addTearDown(router.dispose);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<RecipeSearchService>.value(value: service),
          RepositoryProvider<RecipeFavoritesService>.value(value: favorites),
          RepositoryProvider<RecipeDetailService>.value(
            value: StubRecipeDetailService(),
          ),
          RepositoryProvider<HomeService>.value(value: StubHomeService()),
          RepositoryProvider<FridgeService>.value(value: StubFridgeService()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: ThemeData(colorScheme: AppColors.lightColorScheme),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    AppTapHandler.resetLock();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Home search and all six shortcuts open the same route with the right filter',
    (tester) async {
      final router = await open(tester, path: '/home');
      await tap(tester, find.byKey(const ValueKey('home_search')));
      expect(find.byType(RecipeSearchScreen), findsOneWidget);
      expect(service.requests.last.filter, RecipeSearchFilter.all);
      expect(router.canPop(), isTrue);
      router.pop();
      await tester.pumpAndSettle();
      for (final entry in {
        'cat_all': RecipeSearchFilter.all,
        'cat_new': RecipeSearchFilter.newest,
        'cat_eat_clean': RecipeSearchFilter.eatClean,
        'cat_fast': RecipeSearchFilter.quick,
        'cat_soup': RecipeSearchFilter.soup,
        'cat_vegetarian': RecipeSearchFilter.vegetarian,
      }.entries) {
        await tap(tester, find.byKey(ValueKey('home_category_${entry.key}')));
        expect(find.byType(RecipeSearchScreen), findsOneWidget);
        expect(service.requests.last.filter, entry.value);
        expect(
          tester
              .widget<AppChoiceChip>(
                find.byKey(ValueKey('search_filter_${entry.value.id}')),
              )
              .selected,
          isTrue,
        );
        router.pop();
        await tester.pumpAndSettle();
      }
      await tester.drag(
        find.byKey(const PageStorageKey('home_content')),
        const Offset(0, 800),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('home_search')));
      expect(find.byType(RecipeSearchScreen), findsOneWidget);
      expect(service.requests.last.filter, RecipeSearchFilter.all);
    },
  );

  testWidgets(
    'search clears and retypes, opens detail and back preserves query, filter and favorites',
    (tester) async {
      final router = await open(tester, path: '/home');
      await tap(tester, find.byKey(const ValueKey('home_search')));
      final field = find.byKey(const ValueKey('recipe_search_query'));
      await tester.enterText(field, 'ca hoi');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('1 món ăn'), findsOneWidget);
      await tap(tester, find.byTooltip('Xóa tìm kiếm'));
      expect(
        tester
            .widget<TextFormField>(
              find.descendant(
                of: field,
                matching: find.byType(TextFormField),
                matchRoot: true,
              ),
            )
            .controller!
            .text,
        '',
      );
      expect(find.text('8 món ăn'), findsOneWidget);
      await tester.enterText(field, 'ca hoi');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('search_filter_eat_clean')));
      final original = tester
          .element(find.byType(RecipeSearchResults))
          .read<RecipeSearchCubit>();
      final card = find.byType(ProductCard).first;
      final favorite = find.descendant(
        of: card,
        matching: find.byIcon(PhosphorIconsRegular.heart),
      );
      // No global lock reset here: a navigation callback must not lock the route.
      await tester.ensureVisible(favorite);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(favorite);
      await tester.pumpAndSettle();
      expect(favorites.values['ca_hoi_ap_chao'], isTrue);
      await tap(tester, find.text(detailFixture('ca_hoi_ap_chao').title));
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/recipe/ca_hoi_ap_chao',
      );
      router.pop();
      await tester.pumpAndSettle();
      expect(
        tester
            .element(find.byType(RecipeSearchResults))
            .read<RecipeSearchCubit>(),
        same(original),
      );
      expect(
        tester
            .widget<TextFormField>(
              find.descendant(
                of: field,
                matching: find.byType(TextFormField),
                matchRoot: true,
              ),
            )
            .controller!
            .text,
        'ca hoi',
      );
      expect(original.state.request.filter, RecipeSearchFilter.eatClean);
      expect(original.state.recipes.single.isFavorite, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty results, retry and encoded initial query work', (
    tester,
  ) async {
    service.onSearch = (_) async => throw StateError('offline');
    await open(
      tester,
      path: PathRouter.recipeSearch(
        filter: RecipeSearchFilter.soup,
        query: 'Cá hồi & rau + ớt',
      ),
    );
    expect(service.requests.single.query, 'Cá hồi & rau + ớt');
    expect(find.text('Thử lại'), findsOneWidget);
    service.onSearch = (_) async => [];
    await tap(tester, find.text('Thử lại'));
    expect(service.requests.last.filter, RecipeSearchFilter.soup);
    expect(find.textContaining('Chưa có món phù hợp'), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
    expect(PathRouter.recipeSearch(), '/recipes/search');
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 800.0, 1024.0, 1280.0]) {
    testWidgets('search fits width $width, large text and keyboard', (
      tester,
    ) async {
      final router = await open(tester, width: width, scale: 1.5);
      expect(find.text('8 món ăn'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.byKey(const ValueKey('recipe_search_query')),
        'zzzzzz',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      router.go('/home');
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('home_category_cat_all')));
      expect(find.text('8 món ăn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
