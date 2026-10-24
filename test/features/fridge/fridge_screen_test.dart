import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';

import '../../support/test_text_styles.dart';

import 'package:app_bep_xinh/features/fridge/cubits/fridge/fridge_cubit.dart';
import 'package:app_bep_xinh/features/fridge/screens/fridge_screen.dart';
import 'package:app_bep_xinh/features/fridge/widgets/fridge_card.dart';
import 'package:app_bep_xinh/features/fridge/widgets/fridge_content.dart';
import 'package:app_bep_xinh/features/fridge/widgets/fridge_recipe_suggestions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:app_bep_xinh/features/fridge/models/fridge_summary.dart';

import '../../support/mock_services.dart';

void main() {
  setUpAll(configureTestTextStyles);

  setUp(AppTapHandler.resetLock);

  Widget host(Widget child, {double textScale = 1}) =>
      RepositoryProvider<FridgeService>(
        create: (_) => createMockFridgeService(),
        child: MaterialApp(
          theme: ThemeData(colorScheme: AppColors.lightColorScheme),
          builder: (context, child) => ResponsiveBreakpoints.builder(
            breakpoints: const [
              Breakpoint(start: 0, end: 599, name: MOBILE),
              Breakpoint(start: 600, end: double.infinity, name: TABLET),
            ],
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
          ),
          home: child,
        ),
      );

  testWidgets('search, clear, retype, add, remove and clear inventory', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(const FridgeScreen()));
    await tester.pumpAndSettle();
    final cubit = tester
        .element(find.byType(FridgeContent))
        .read<FridgeCubit>();
    final search = find.byKey(const ValueKey('fridge_ingredient_search'));

    await tester.enterText(search, 'thit bo');
    await tester.pump();
    expect(find.byKey(const ValueKey('pick_beef')), findsOneWidget);
    expect(find.byKey(const ValueKey('pick_egg')), findsNothing);

    await tester.enterText(search, '');
    await tester.pump();
    expect(find.byKey(const ValueKey('pick_egg')), findsOneWidget);
    await tester.enterText(search, 'thịt bò');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('pick_beef')));
    await tester.pumpAndSettle();
    expect(cubit.state.selectedIds, contains('beef'));
    expect(find.text('Nấu được ngay · 3 món'), findsOneWidget);

    // Throttle uses wall time; isolate successive interaction assertions.
    AppTapHandler.resetLock();
    await tester.tap(find.byKey(const ValueKey('remove_beef')));
    await tester.pumpAndSettle();
    expect(cubit.state.selectedIds, isNot(contains('beef')));
    expect(find.text('Nấu được ngay · 2 món'), findsOneWidget);

    AppTapHandler.resetLock();
    await tester.tap(find.text('Xóa hết'));
    await tester.pumpAndSettle();
    expect(cubit.state.selectedIds, isEmpty);
    expect(find.text('Trong tủ lạnh (0)'), findsOneWidget);
    expect(
      find.text('Thêm nguyên liệu để xem món có thể nấu nhé.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('recipe filter updates displayed results', (tester) async {
    final cubit = FridgeCubit(service: createMockFridgeService());
    await cubit.loadFridge();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      host(
        BlocProvider.value(
          value: cubit,
          child: const Scaffold(
            body: SingleChildScrollView(child: FridgeRecipeSuggestions()),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Món chay'));
    await tester.pumpAndSettle();
    expect(cubit.state.filter, FridgeRecipeFilter.vegetarian);
    expect(find.text('Đậu hũ sốt cà chua'), findsOneWidget);
    expect(find.text('Canh cà chua trứng'), findsNothing);
    expect(find.text('Bò xào cà chua'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 700), const Size(800, 1024)]) {
    testWidgets('layout scrolls without overflow at $size and large text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(host(const FridgeScreen(), textScale: 1.5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 7; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -350));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Bò xào cà chua'), findsOneWidget);
    });
  }

  testWidgets('Home fridge card retains original content and explore action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = false;
    await tester.pumpWidget(
      host(
        Scaffold(
          body: FridgeCard(
            summary: FridgeSummary.fromData(fridgeFixture()),
            onExploreTap: () => opened = true,
          ),
        ),
      ),
    );
    expect(find.text('Gợi ý'), findsOneWidget);
    expect(find.text('Nấu được 2 món ngon'), findsOneWidget);
    await tester.tap(find.text('Khám phá ngay'));
    await tester.pumpAndSettle();
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });
}
