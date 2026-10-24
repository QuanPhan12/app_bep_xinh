import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';

import 'dart:async';

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';
import 'package:app_bep_xinh/features/fridge/models/fridge_summary.dart';
import 'package:app_bep_xinh/features/fridge/screens/fridge_screen.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:app_bep_xinh/features/home/models/home_category.dart';
import 'package:app_bep_xinh/features/home/models/home_data.dart';
import 'package:app_bep_xinh/features/home/screens/home_screen.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../support/mock_services.dart';
import '../support/test_text_styles.dart';

void main() {
  setUpAll(configureTestTextStyles);
  setUp(AppTapHandler.resetLock);

  Widget host(Widget child, {HomeService? home, FridgeService? fridge}) =>
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<HomeService>.value(
            value: home ?? StubHomeService(),
          ),
          RepositoryProvider<FridgeService>.value(
            value: fridge ?? StubFridgeService(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(colorScheme: AppColors.lightColorScheme),
          builder: (context, child) => ResponsiveBreakpoints.builder(
            breakpoints: const [
              Breakpoint(start: 0, end: 599, name: MOBILE),
              Breakpoint(start: 600, end: double.infinity, name: TABLET),
            ],
            child: child!,
          ),
          home: child,
        ),
      );

  HomeData response({bool empty = false}) => HomeData(
    banners: [],
    recipes: [],
    categories: empty
        ? []
        : const [
            HomeCategory(
              id: 'from_service',
              title: 'Danh mục từ service',
              icon: 'fast',
            ),
          ],
    fridgeSummary: FridgeSummary(ingredientNames: ['Gạo'], readyRecipeCount: 7),
  );

  testWidgets(
    'Home shows loading then renders service categories and fridge summary',
    (tester) async {
      tester.view.physicalSize = const Size(440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = StubHomeService();
      final pending = Completer<HomeData>();
      service.onFetch = () => pending.future;
      await tester.pumpWidget(host(const HomeScreen(), home: service));
      expect(find.byType(AppSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      pending.complete(response());
      await tester.pumpAndSettle();
      expect(find.text('Danh mục từ service'), findsOneWidget);
      expect(find.text('Nấu được 7 món ngon'), findsOneWidget);
      expect(find.text('Món mới'), findsNothing);
    },
  );

  testWidgets('Home fetch error shows retry and recovers to empty response', (
    tester,
  ) async {
    final service = StubHomeService();
    service.onFetch = () => Future.error(StateError('offline'));
    await tester.pumpWidget(host(const HomeScreen(), home: service));
    await tester.pumpAndSettle();
    expect(
      find.text('Không tải được trang chủ. Vui lòng thử lại.'),
      findsOneWidget,
    );
    service.onFetch = () async => response(empty: true);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có nội dung trang chủ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Fridge fetch error retries and renders ingredients returned by service',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = StubFridgeService();
      service.onFetch = () => Future.error(StateError('offline'));
      await tester.pumpWidget(host(const FridgeScreen(), fridge: service));
      await tester.pumpAndSettle();
      expect(
        find.text('Không tải được tủ lạnh. Vui lòng thử lại.'),
        findsOneWidget,
      );
      service.onFetch = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pick_egg')), findsOneWidget);
      expect(find.text('Trong tủ lạnh (4)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 800.0]) {
    testWidgets('loaded Home scrolls with large text at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(
        host(
          MediaQuery(
            data: MediaQueryData(
              size: Size(width, 1000),
              textScaler: TextScaler.linear(1.5),
            ),
            child: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('retry state can scroll in a short viewport with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: AppLoadState(
              message: 'Không tải được dữ liệu. Vui lòng kiểm tra và thử lại.',
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Thử lại'));
    expect(tester.takeException(), isNull);
  });
}
