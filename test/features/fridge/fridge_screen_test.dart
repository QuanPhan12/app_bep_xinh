import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:app_bep_xinh/features/fridge/widgets/fridge_ingredient_chip.dart';

import '../../support/test_text_styles.dart';

import 'package:app_bep_xinh/features/fridge/cubits/fridge/fridge_cubit.dart';
import 'package:app_bep_xinh/features/fridge/screens/fridge_screen.dart';
import 'package:app_bep_xinh/features/fridge/widgets/fridge_card.dart';
import 'package:app_bep_xinh/features/fridge/widgets/fridge_content.dart';
import 'package:app_bep_xinh/features/fridge/widgets/fridge_recipe_suggestions.dart';
import 'package:app_bep_xinh/features/fridge/widgets/fridge_inventory_card.dart';
import 'package:app_bep_xinh/features/product/widgets/product_card.dart';
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

  Widget host(Widget child, {double textScale = 1, FridgeService? service}) =>
      RepositoryProvider<FridgeService>(
        create: (_) => service ?? createMockFridgeService(),
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

  Future<void> tap(WidgetTester tester, Finder finder) async {
    AppTapHandler.resetLock();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('search, clear, retype, add, remove and clear inventory', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(const FridgeScreen()));
    await tester.pumpAndSettle();
    final cubit = tester
        .element(find.byType(FridgeContent))
        .read<FridgeCubit>();
    final search = find.byKey(const ValueKey('fridge_ingredient_search'));
    expect(search, findsNothing);
    final firstRecipe = find.text('Đậu hũ sốt cà chua');
    expect(
      tester.getSize(find.byType(FridgeInventoryCard)).height,
      lessThanOrEqualTo(144),
    );
    expect(find.text('Đủ nguyên liệu'), findsNothing);
    final firstCard = find.byType(ProductCard).first;
    final firstTime = find.descendant(
      of: firstCard,
      matching: find.text('15p'),
    );
    expect(
      tester.getBottomRight(firstCard).dy - tester.getBottomRight(firstTime).dy,
      lessThan(26),
    );
    expect(tester.getBottomLeft(firstRecipe).dy, lessThan(760));
    await tap(tester, find.byKey(const ValueKey('fridge_add_ingredients')));

    await tester.enterText(search, 'thit bo');
    await tester.pump();
    expect(find.byKey(const ValueKey('pick_beef')), findsOneWidget);
    expect(find.byKey(const ValueKey('pick_egg')), findsNothing);

    await tap(tester, find.byTooltip('Xóa tìm kiếm'));
    expect(find.byKey(const ValueKey('pick_egg')), findsOneWidget);
    await tester.enterText(search, 'thịt bò');
    await tester.pump();
    await tap(tester, find.byKey(const ValueKey('pick_beef')));
    expect(cubit.state.selectedIds, contains('beef'));
    await tap(tester, find.text('Xem gợi ý'));
    expect(find.byKey(const ValueKey('fridge_ingredient_sheet')), findsNothing);
    expect(find.text('Nấu được ngay · 3 món'), findsOneWidget);

    // Throttle uses wall time; isolate successive interaction assertions.
    await tap(tester, find.byKey(const ValueKey('fridge_add_ingredients')));
    await tap(tester, find.byKey(const ValueKey('pick_beef')));
    await tap(tester, find.text('Xem gợi ý'));
    expect(cubit.state.selectedIds, isNot(contains('beef')));
    expect(find.text('Nấu được ngay · 2 món'), findsOneWidget);

    expect(find.text('Xóa hết'), findsNothing);
    await tap(tester, find.byKey(const ValueKey('fridge_add_ingredients')));
    await tap(tester, find.text('Xóa hết'));
    await tap(tester, find.text('Xem gợi ý'));
    expect(cubit.state.selectedIds, isEmpty);
    expect(find.text('Nguyên liệu (0)'), findsOneWidget);
    expect(
      find.text('Thêm nguyên liệu để xem món có thể nấu nhé.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sheet reopens with a fresh query and keeps saved selections', (
    tester,
  ) async {
    await tester.pumpWidget(host(const FridgeScreen()));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('fridge_add_ingredients')));
    final search = find.byKey(const ValueKey('fridge_ingredient_search'));
    await tester.enterText(search, 'thit bo');
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('pick_beef')));
    await tap(tester, find.byTooltip('Đóng bảng nguyên liệu'));
    expect(find.byKey(const ValueKey('inventory_beef')), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('fridge_add_ingredients')));
    expect(
      tester
          .widget<TextFormField>(
            find.descendant(
              of: search,
              matching: find.byType(TextFormField),
              matchRoot: true,
            ),
          )
          .controller!
          .text,
      '',
    );
    expect(
      tester
          .widget<FridgeIngredientChip>(find.byKey(const ValueKey('pick_beef')))
          .selected,
      isTrue,
    );
    await tap(tester, find.byKey(const ValueKey('pick_beef')));
    await tap(tester, find.text('Xem gợi ý'));
    expect(find.byKey(const ValueKey('inventory_beef')), findsNothing);
    expect(find.text('Nấu được ngay · 2 món'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed selection rolls back in the sheet and can be retried', (
    tester,
  ) async {
    final service = StubFridgeService()
      ..onSave = (_) async => throw StateError('offline');
    await tester.pumpWidget(host(const FridgeScreen(), service: service));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('fridge_add_ingredients')));
    await tap(tester, find.byKey(const ValueKey('pick_beef')));
    expect(
      tester
          .widget<FridgeIngredientChip>(find.byKey(const ValueKey('pick_beef')))
          .selected,
      isFalse,
    );
    expect(
      find.text('Chưa lưu được nguyên liệu. Vui lòng thử lại.'),
      findsOneWidget,
    );
    service.onSave = null;
    await tap(tester, find.byKey(const ValueKey('pick_beef')));
    await tap(tester, find.text('Xem gợi ý'));
    expect(find.byKey(const ValueKey('inventory_beef')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    AppMessenger.hide();
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 700),
    const Size(800, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets('ingredient sheet fits $size, large text and keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(host(const FridgeScreen(), textScale: 1.5));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('fridge_add_ingredients')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('fridge_ingredient_search'));
      await tester.ensureVisible(search);
      await tester.enterText(search, 'thit bo');
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('pick_beef')));
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      tester.view.physicalSize = Size(size.height, size.width);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.descendant(
                of: search,
                matching: find.byType(TextFormField),
                matchRoot: true,
              ),
            )
            .controller!
            .text,
        'thit bo',
      );
      await tap(tester, find.text('Xem gợi ý'));
      expect(find.byKey(const ValueKey('inventory_beef')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

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
        await tester.drag(
          find.byType(CustomScrollView).last,
          const Offset(0, -350),
        );
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
