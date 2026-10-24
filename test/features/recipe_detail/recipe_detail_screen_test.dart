import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:app_bep_xinh/core/widgets/app_app_bar.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';
import 'package:app_bep_xinh/core/widgets/app_serving_selector.dart';
import 'package:app_bep_xinh/features/recipe_detail/screens/recipe_detail_screen.dart';
import 'package:app_bep_xinh/features/recipe_detail/models/recipe_detail.dart';
import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';

import '../../support/mock_services.dart';
import '../../support/recipe_detail_fakes.dart';
import '../../support/test_text_styles.dart';

void main() {
  setUpAll(configureTestTextStyles);
  late StubRecipeDetailService service;
  late StubRecipeFavoritesService favorites;
  setUp(() {
    AppTapHandler.resetLock();
    service = StubRecipeDetailService();
    favorites = StubRecipeFavoritesService();
  });
  tearDown(() => favorites.dispose());
  GoRouter router() => GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Trang trước')),
      ),
      GoRoute(
        path: PathRouter.recipeDetailScreen,
        builder: (_, state) =>
            RecipeDetailScreen(recipeId: state.pathParameters['id']!),
      ),
    ],
  );
  Widget host(GoRouter router, {double scale = 1}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<RecipeDetailService>.value(value: service),
      RepositoryProvider<RecipeFavoritesService>.value(value: favorites),
      RepositoryProvider<HomeService>.value(value: StubHomeService()),
      RepositoryProvider<FridgeService>.value(value: StubFridgeService()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: ThemeData(colorScheme: AppColors.lightColorScheme),
      builder: (context, child) => ResponsiveBreakpoints.builder(
        breakpoints: const [
          Breakpoint(start: 0, end: 599, name: MOBILE),
          Breakpoint(start: 600, end: double.infinity, name: TABLET),
        ],
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  Future<void> open(
    WidgetTester tester,
    GoRouter route, {
    String id = 'bo_ne_tieu_den',
    double width = 390,
    double height = 1600,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(route.dispose);
    addTearDown(() async {
      AppMessenger.hide();
      await tester.pumpWidget(const SizedBox.shrink());
    });
    await tester.pumpWidget(host(route, scale: scale));
    route.push(PathRouter.recipeDetail(id));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    AppTapHandler.resetLock();
    await tester.pump();
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'uses route id, shared UI, changes servings and ingredient checks',
    (tester) async {
      await open(tester, router(), id: 'salad_uc_ga_me_rang');
      expect(find.text('Salad ức gà sốt mè rang'), findsOneWidget);
      expect(find.text('Bò né sốt tiêu đen bánh mì'), findsNothing);
      expect(find.byType(AppAppBar), findsOneWidget);
      expect(find.byType(AppServingSelector), findsOneWidget);
      expect(find.text('250 g'), findsOneWidget);
      await tap(tester, find.bySemanticsLabel('Tăng khẩu phần'));
      expect(find.text('375 g'), findsOneWidget);
      final tile = find.byKey(const ValueKey('detail_ingredient_chicken'));
      expect(tester.widget<CheckboxListTile>(tile).value, isFalse);
      await tap(tester, tile);
      expect(tester.widget<CheckboxListTile>(tile).value, isTrue);
      await tap(tester, find.text('Cách nấu (4)'));
      expect(find.text('Bước 1'), findsOneWidget);
    },
  );
  testWidgets(
    'draft-independent skeleton, load error retry and unknown recipe',
    (tester) async {
      final pending = Completer<RecipeDetailData>();
      service.onFetch = (_) => pending.future;
      final route = router();
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(route.dispose);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(host(route));
      route.push(PathRouter.recipeDetail('bo_ne_tieu_den'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AppSkeleton), findsOneWidget);
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không tải được công thức. Vui lòng thử lại.'),
        findsOneWidget,
      );
      service.onFetch = null;
      await tap(tester, find.text('Thử lại'));
      expect(find.text('Bò né sốt tiêu đen bánh mì'), findsOneWidget);
      await tap(tester, find.byTooltip('Quay lại'));
      service.onFetch = (_) => Future.error(const RecipeNotFoundException());
      route.push(PathRouter.recipeDetail('missing'));
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy công thức này.'), findsOneWidget);
      expect(find.text('Bắt đầu nấu'), findsNothing);
    },
  );
  testWidgets(
    'favorite failure retries and cooking moves through steps then completes',
    (tester) async {
      await open(tester, router());
      favorites.onSet = (_, _) => Future.error(StateError('offline'));
      await tap(tester, find.byTooltip('Lưu món'));
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Đã có lỗi xảy ra'), findsOneWidget);
      expect(
        find.text('Chưa lưu được món yêu thích. Vui lòng thử lại.'),
        findsOneWidget,
      );
      favorites.onSet = null;
      AppMessenger.hide();
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('Lưu món'));
      expect(find.byTooltip('Bỏ lưu món'), findsOneWidget);
      await tap(tester, find.text('Bắt đầu nấu'));
      expect(find.text('Đang nấu'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Bò né sốt tiêu đen bánh mì')).dy,
        lessThan(160),
      );
      expect(find.text('Bước 1 / 4'), findsOneWidget);
      await tap(tester, find.text('Bước tiếp theo'));
      expect(find.text('Bước 2 / 4'), findsOneWidget);
      await tap(tester, find.text('Bước trước'));
      expect(find.text('Bước 1 / 4'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tap(tester, find.text('Bước tiếp theo'));
      }
      await tap(tester, find.text('Hoàn tất'));
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Thành công'), findsOneWidget);
      expect(find.text('Bạn đã hoàn thành món ăn.'), findsOneWidget);
      await tap(tester, find.byTooltip('Quay lại'));
      expect(find.text('Trang trước'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('Thành công'), findsNothing);
    },
  );
  for (final width in [320.0, 800.0]) {
    testWidgets('detail remains usable at width $width and large text', (
      tester,
    ) async {
      await open(tester, router(), width: width, height: 900, scale: 1.5);
      await tap(tester, find.bySemanticsLabel('Tăng khẩu phần'));
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('Cách nấu (4)'));
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('Bắt đầu nấu'));
      expect(tester.takeException(), isNull);
      await tap(tester, find.text('Bước tiếp theo'));
      expect(tester.takeException(), isNull);
    });
  }
  for (final source in [PathRouter.homeScreen, PathRouter.fridgeScreen]) {
    testWidgets(
      'recipe cards from $source open correct detail via app routes',
      (tester) async {
        final route = GoRouter(
          routes: appRouter.configuration.routes,
          initialLocation: source,
        );
        tester.view.physicalSize = const Size(390, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(route.dispose);
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
        await tester.pumpWidget(host(route));
        await tester.pumpAndSettle();
        final title = source == PathRouter.homeScreen
            ? 'Bò né sốt tiêu đen bánh mì'
            : 'Đậu hũ sốt cà chua';
        await tap(tester, find.text(title));
        expect(find.byType(RecipeDetailScreen), findsOneWidget);
        expect(find.text(title), findsOneWidget);
        await tap(tester, find.byTooltip('Quay lại'));
        expect(find.byType(RecipeDetailScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
