import 'package:app_bep_xinh/features/recipe_search/services/recipe_search_service.dart';

import '../support/recipe_search_fakes.dart';

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/widgets/app_feature_theme.dart';
import 'package:app_bep_xinh/features/navigation/widgets/app_bottom_nav_bar.dart';
import 'package:app_bep_xinh/features/recipe_editor/screens/recipe_editor_screen.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:app_bep_xinh/features/fridge/widgets/fridge_inventory_card.dart';
import 'package:app_bep_xinh/features/fridge/widgets/fridge_recipe_suggestions.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/profile/services/profile_service.dart';
import 'package:app_bep_xinh/features/profile/services/public_profile_service.dart';
import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';
import 'package:app_bep_xinh/features/recipe_detail/widgets/recipe_detail_overview.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_cover_picker.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_editor_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/cubits/recipe_editor/recipe_editor_cubit.dart';
import 'package:app_bep_xinh/features/recipe_editor/widgets/recipe_editor_form.dart';
import 'package:app_bep_xinh/features/recipe_editor/widgets/recipe_cover_field.dart';
import 'package:app_bep_xinh/features/recipe_editor/widgets/recipe_details_fields.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/mock_services.dart';
import '../support/profile_fakes.dart';
import '../support/public_profile_fakes.dart';
import '../support/recipe_detail_fakes.dart';
import '../support/recipe_editor_fakes.dart';
import '../support/test_text_styles.dart';

void main() {
  setUpAll(() {
    configureTestTextStyles();
    AppTextStyles.headlineMedium = const TextStyle(fontSize: 22);
  });
  setUp(AppTapHandler.resetLock);

  Future<GoRouter> open(
    WidgetTester tester,
    Size size, {
    String path = '/login',
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: appRouter.configuration.routes,
      initialLocation: path,
    );
    final favorites = StubRecipeFavoritesService();
    final profile = StubProfileService();
    final publicProfiles = StubPublicProfileService();
    addTearDown(router.dispose);
    addTearDown(favorites.dispose);
    addTearDown(profile.dispose);
    addTearDown(publicProfiles.dispose);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<HomeService>.value(value: StubHomeService()),
          RepositoryProvider<RecipeSearchService>.value(
            value: StubRecipeSearchService(),
          ),
          RepositoryProvider<FridgeService>.value(value: StubFridgeService()),
          RepositoryProvider<RecipeFavoritesService>.value(value: favorites),
          RepositoryProvider<ProfileService>.value(value: profile),
          RepositoryProvider<PublicProfileService>.value(value: publicProfiles),
          RepositoryProvider<RecipeDetailService>.value(
            value: StubRecipeDetailService(),
          ),
          RepositoryProvider<IngredientCatalogService>(
            create: (_) => MockIngredientCatalogService(fixtureApi()),
          ),
          RepositoryProvider<RecipeEditorService>.value(
            value: StubRecipeEditorService()..saved = validRecipeDraft(),
          ),
          RepositoryProvider<RecipeCoverPicker>.value(
            value: StubRecipeCoverPicker(),
          ),
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

  for (final size in [const Size(390, 844), const Size(1024, 768)]) {
    testWidgets('add recipe never selects a navigation tab at $size', (
      tester,
    ) async {
      final router = await open(tester, size, path: '/home');
      ConvexAppBarState bar({bool offstage = false}) =>
          tester.state<ConvexAppBarState>(
            find.byType(ConvexAppBar, skipOffstage: !offstage),
          );
      Future<void> tap(Finder target) async {
        expect(AppTapHandler.isBusy, isFalse);
        AppTapHandler.resetLock();
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Finder navIcon(IconData icon) => find.descendant(
        of: find.byType(AppBottomNavBar),
        matching: find.byIcon(icon),
      );

      for (final entry in [
        (0, CupertinoIcons.house_fill, '/home'),
        (1, Icons.kitchen_outlined, '/fridge'),
        (2, CupertinoIcons.cart, '/cart'),
        (3, CupertinoIcons.person, '/profile'),
      ]) {
        if (entry.$1 != 0) await tap(navIcon(entry.$2));
        final selected = entry.$1 < 2 ? entry.$1 : entry.$1 + 1;
        expect(bar().currentIndex, selected);
        expect(
          router.routerDelegate.currentConfiguration.last.matchedLocation,
          entry.$3,
        );
        await tap(navIcon(Icons.add_rounded));
        expect(find.byType(RecipeEditorScreen), findsOneWidget);
        expect(bar(offstage: true).currentIndex, selected);
        await tap(find.byTooltip('Quay lại'));
        expect(find.byType(RecipeEditorScreen), findsNothing);
        expect(bar().currentIndex, selected);
        expect(router.canPop(), isFalse);

        // Reselecting the branch must not leave the central action highlighted.
        expect(AppTapHandler.isBusy, isFalse);
        AppTapHandler.resetLock();
        bar().tap(selected);
        await tester.pumpAndSettle();
        expect(bar().currentIndex, selected);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('feature styling stays isolated from Home, Cart and Auth', (
    tester,
  ) async {
    final router = await open(tester, const Size(390, 844), path: '/home');
    for (final path in [
      '/home',
      '/fridge',
      '/cart',
      '/profile',
      '/home',
      '/recipes/search',
      '/recipe/bo_ne_tieu_den',
      '/cart',
      '/login',
      '/register',
      '/forgot-password',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(
        find.byType(AppFeatureTheme),
        const {
              '/home',
              '/cart',
              '/login',
              '/register',
              '/forgot-password',
            }.contains(path)
            ? findsNothing
            : findsOneWidget,
        reason: path,
      );
      expect(tester.takeException(), isNull, reason: path);
    }
  });

  testWidgets('all polished routes fit a small phone with large text', (
    tester,
  ) async {
    final router = await open(tester, const Size(320, 844), scale: 1.5);
    for (final path in [
      '/login',
      '/register',
      '/forgot-password',
      '/fridge',
      '/profile',
      '/users/linh_nguyen',
      '/settings',
      '/recipe/bo_ne_tieu_den',
      '/recipes/new',
      '/recipes/search',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: path);
      final scrollable = find.byType(Scrollable);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -450));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull, reason: '$path after scrolling');
    }
  });

  for (final size in [
    const Size(600, 960),
    const Size(800, 1100),
    const Size(1024, 768),
    const Size(1280, 800),
  ]) {
    testWidgets(
      'all routes fit tablet $size with large text and scroll to their content',
      (tester) async {
        final router = await open(tester, size, scale: 1.5);
        for (final path in [
          '/login',
          '/register',
          '/forgot-password',
          '/home',
          '/fridge',
          '/cart',
          '/profile',
          '/users/linh_nguyen',
          '/settings',
          '/recipe/bo_ne_tieu_den',
          '/recipes/new',
          '/recipes/search',
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$path at $size');
          for (var scroll = 0; scroll < 3; scroll++) {
            final scrollable = find.byType(Scrollable);
            if (scrollable.evaluate().isNotEmpty) {
              await tester.drag(scrollable.first, const Offset(0, -300));
              await tester.pumpAndSettle();
            }
            expect(
              tester.takeException(),
              isNull,
              reason: '$path scrolling at $size',
            );
          }
        }
      },
    );
  }

  testWidgets(
    'wide layouts place fridge and recipe detail panes beside each other',
    (tester) async {
      final router = await open(tester, const Size(1024, 768), path: '/fridge');
      expect(
        tester.getTopLeft(find.byType(FridgeRecipeSuggestions)).dx,
        greaterThan(
          tester.getTopLeft(find.byType(FridgeInventoryCard)).dx + 350,
        ),
      );
      router.go('/recipe/bo_ne_tieu_den');
      await tester.pumpAndSettle();
      expect(
        tester
            .getTopLeft(
              find
                  .byWidgetPredicate((widget) => widget is SegmentedButton)
                  .first,
            )
            .dx,
        greaterThan(
          tester.getTopLeft(find.byType(RecipeDetailOverview)).dx + 350,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final entry in {
    '/login': 'Đăng nhập',
    '/register': 'Đăng ký',
    '/forgot-password': 'Gửi liên kết khôi phục',
  }.entries) {
    testWidgets(
      'auth ${entry.key} keeps mobile form and entered values across sizes',
      (tester) async {
        await open(tester, const Size(390, 844), path: entry.key, scale: 1.5);
        final field = find.byType(TextFormField).first;
        final originalElement = tester.element(field);
        await tester.enterText(field, 'mobile@tablet.test');
        for (final size in [
          const Size(800, 1100),
          const Size(1100, 800),
          const Size(600, 960),
          const Size(390, 844),
        ]) {
          tester.view.physicalSize = size;
          await tester.pumpAndSettle();
          expect(tester.element(field), same(originalElement));
          expect(find.text('mobile@tablet.test'), findsOneWidget);
          expect(tester.getSize(field).width, lessThanOrEqualTo(440));
          expect(tester.takeException(), isNull);
        }
        tester.view.physicalSize = const Size(1100, 800);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(entry.value),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('mobile@tablet.test'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'recipe editor keeps its draft through every stage and a tablet rotation',
    (tester) async {
      await open(
        tester,
        const Size(1024, 768),
        path: '/recipes/new',
        scale: 1.5,
      );
      final cubit = tester
          .element(find.byType(RecipeEditorForm))
          .read<RecipeEditorCubit>();
      expect(
        tester.getTopLeft(find.byType(RecipeDetailsFields)).dx,
        greaterThan(tester.getTopLeft(find.byType(RecipeCoverField)).dx + 350),
      );
      cubit.changeTitle('Công thức trên tablet');
      for (var stage = 0; stage < 3; stage++) {
        cubit.nextStep();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(cubit.state.step, RecipeEditorStep.review);
      expect(find.text('Công thức trên tablet'), findsOneWidget);
      tester.view.physicalSize = const Size(768, 1024);
      await tester.pumpAndSettle();
      expect(cubit.state.draft.title, 'Công thức trên tablet');
      cubit.goToStep(RecipeEditorStep.details);
      await tester.pumpAndSettle();
      expect(find.text('Công thức trên tablet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shopping checks persist when the tablet changes orientation', (
    tester,
  ) async {
    await open(tester, const Size(800, 1100), path: '/cart');
    final item = find.text('Khoai tây');
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();
    expect(find.text('Đã chuẩn bị 4 trên 8 món'), findsOneWidget);
    tester.view.physicalSize = const Size(1100, 800);
    await tester.pumpAndSettle();
    expect(find.text('Đã chuẩn bị 4 trên 8 món'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
