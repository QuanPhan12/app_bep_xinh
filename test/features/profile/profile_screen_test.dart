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
import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:app_bep_xinh/features/navigation/widgets/app_bottom_nav_bar.dart';
import 'package:app_bep_xinh/features/product/widgets/product_card.dart';
import 'package:app_bep_xinh/features/profile/models/profile_data.dart';
import 'package:app_bep_xinh/features/profile/screens/profile_screen.dart';
import 'package:app_bep_xinh/features/profile/services/profile_service.dart';
import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:app_bep_xinh/features/settings/screens/settings_screen.dart';

import '../../support/mock_services.dart';
import '../../support/profile_fakes.dart';
import '../../support/recipe_detail_fakes.dart';
import '../../support/test_text_styles.dart';

void main() {
  setUpAll(configureTestTextStyles);
  late StubProfileService service;
  late StubRecipeFavoritesService favorites;
  setUp(() {
    AppTapHandler.resetLock();
    service = StubProfileService();
    favorites = StubRecipeFavoritesService();
  });
  tearDown(() async {
    await service.dispose();
    await favorites.dispose();
  });

  GoRouter router() => GoRouter(
    routes: appRouter.configuration.routes,
    initialLocation: PathRouter.profileScreen,
  );
  Widget host(GoRouter route, {double scale = 1}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ProfileService>.value(value: service),
      RepositoryProvider<RecipeFavoritesService>.value(value: favorites),
      RepositoryProvider<RecipeDetailService>.value(
        value: StubRecipeDetailService(),
      ),
      RepositoryProvider<HomeService>.value(value: StubHomeService()),
      RepositoryProvider<FridgeService>.value(value: StubFridgeService()),
    ],
    child: MaterialApp.router(
      routerConfig: route,
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
    double width = 390,
    double height = 950,
    double scale = 1,
    bool settle = true,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(route.dispose);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(host(route, scale: scale));
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    AppTapHandler.resetLock();
    await tester.pump();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'profile reuses shared cards, opens correct recipe and syncs saved tab',
    (tester) async {
      final route = router();
      await open(tester, route, height: 1600);
      expect(find.byType(AppAppBar), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byTooltip('Cài đặt'), findsOneWidget);
      expect(find.text('Mai Anh'), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(2));
      await tap(tester, find.text('Đã lưu').last);
      expect(find.text('Salad ức gà sốt mè rang'), findsOneWidget);
      await tap(tester, find.byIcon(Icons.favorite_rounded));
      expect(find.textContaining('Chưa có món đã lưu.'), findsOneWidget);
      await favorites.setFavorite('bo_ne_tieu_den', true);
      await tester.pumpAndSettle();
      await tap(tester, find.text('Bò né sốt tiêu đen bánh mì'));
      expect(
        route.routerDelegate.currentConfiguration.last.matchedLocation,
        '/recipe/bo_ne_tieu_den',
      );
      await tap(tester, find.byTooltip('Quay lại'));
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Bò né sốt tiêu đen bánh mì'), findsOneWidget);
    },
  );

  testWidgets(
    'settings opens above shell, visibility updates profile and back retains tab',
    (tester) async {
      final route = router();
      await open(tester, route);
      await tap(tester, find.text('Đã lưu').last);
      await tap(tester, find.byTooltip('Cài đặt'));
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);
      await tap(tester, find.byKey(const ValueKey('settings_show_bio')));
      expect(service.account.showBio, isFalse);
      await tap(tester, find.byTooltip('Quay lại'));
      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.text(service.account.bio), findsNothing);
      expect(find.text('Salad ức gà sốt mè rang'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'editing validates clearing and retyping, saves and shows custom success',
    (tester) async {
      await open(tester, router());
      await tap(tester, find.text('Sửa hồ sơ'));
      expect(AppTapHandler.isBusy, isFalse);
      await tester.enterText(find.byKey(const ValueKey('profile_name')), '');
      await tap(tester, find.text('Lưu thay đổi'));
      expect(service.writes, 0);
      expect(find.text('Nhập tên hiển thị.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('profile_name')),
        'Bếp của An',
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile_bio')),
        'Nấu những món mình yêu.',
      );
      await tap(tester, find.text('Lưu thay đổi'));
      expect(find.text('Bếp của An'), findsOneWidget);
      expect(find.text('Nấu những món mình yêu.'), findsOneWidget);
      expect(find.text('Đã cập nhật hồ sơ.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('skeleton, initial failure and retry', (tester) async {
    final pending = Completer<ProfileData>();
    service.onFetch = () => pending.future;
    await open(tester, router(), settle: false);
    expect(find.byType(AppSkeleton), findsOneWidget);
    pending.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(
      find.text('Không tải được hồ sơ. Vui lòng thử lại.'),
      findsOneWidget,
    );
    service.onFetch = null;
    await tap(tester, find.text('Thử lại'));
    expect(find.text('Mai Anh'), findsOneWidget);
  });

  for (final width in [320.0, 800.0]) {
    testWidgets(
      'profile, settings and edit support width $width, large text and keyboard',
      (tester) async {
        await open(tester, router(), width: width, height: 900, scale: 1.5);
        expect(tester.takeException(), isNull);
        await tap(tester, find.text('Sửa hồ sơ'));
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('profile_name')),
          'Tên khác',
        );
        await tap(tester, find.text('Lưu thay đổi'));
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(find.text('Tên khác'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        await tap(tester, find.byTooltip('Cài đặt'));
        expect(tester.takeException(), isNull);
        await tap(tester, find.byKey(const ValueKey('settings_show_bio')));
        await tap(tester, find.text('Đăng xuất'));
        expect(find.text('Đăng xuất?'), findsOneWidget);
        await tap(tester, find.text('Ở lại'));
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
