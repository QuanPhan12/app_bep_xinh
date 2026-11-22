import 'package:app_bep_xinh/features/profile/services/profile_service.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../../support/profile_fakes.dart';
import '../../support/recipe_detail_fakes.dart';

import 'package:app_bep_xinh/core/widgets/app_selection_controls.dart';
import 'package:app_bep_xinh/features/recipe_editor/widgets/recipe_editor_form.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/screens/recipe_editor_screen.dart';
import 'package:app_bep_xinh/features/recipe_editor/models/recipe_draft.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_cover_picker.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_editor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../support/mock_services.dart';
import '../../support/recipe_editor_fakes.dart';
import '../../support/test_text_styles.dart';

void main() {
  setUpAll(configureTestTextStyles);
  setUp(AppTapHandler.resetLock);
  late StubRecipeEditorService service;
  late StubRecipeCoverPicker picker;

  setUp(() {
    service = StubRecipeEditorService();
    picker = StubRecipeCoverPicker();
  });

  GoRouter createRouter() => GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Trang trước')),
      ),
      GoRoute(
        path: PathRouter.recipeEditorScreen,
        builder: (_, _) => const RecipeEditorScreen(),
      ),
    ],
  );

  Widget host(GoRouter router, {double scale = 1}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ProfileService>(create: (_) => StubProfileService()),
      RepositoryProvider<RecipeFavoritesService>(
        create: (_) => StubRecipeFavoritesService(),
      ),
      RepositoryProvider<IngredientCatalogService>(
        create: (_) => MockIngredientCatalogService(fixtureApi()),
      ),
      RepositoryProvider<RecipeEditorService>.value(value: service),
      RepositoryProvider<RecipeCoverPicker>.value(value: picker),
      RepositoryProvider<HomeService>.value(value: StubHomeService()),
      RepositoryProvider<FridgeService>.value(value: StubFridgeService()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.lightTheme,
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
    GoRouter router, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(router.dispose);
    addTearDown(() async {
      AppMessenger.hide();
      await tester.pumpWidget(const SizedBox.shrink());
    });
    await tester.pumpWidget(host(router, scale: scale));
    router.push(PathRouter.recipeEditorScreen);
    await tester.pumpAndSettle();
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
    'author classifications save and restore through editor controls',
    (tester) async {
      service.saved = validRecipeDraft();
      final router = createRouter();
      await open(tester, router, width: 800, scale: 1.5);
      expect(find.byKey(const ValueKey('recipe_is_banner')), findsNothing);
      for (final category in RecipeCategory.values) {
        await tap(
          tester,
          find.byKey(ValueKey('recipe_category_${category.id}')),
        );
      }
      await tap(tester, find.byKey(const ValueKey('recipe_category_quick')));
      expect(
        tester
            .widget<AppFilterChip>(
              find.byKey(const ValueKey('recipe_category_quick')),
            )
            .selected,
        isFalse,
      );
      await tap(tester, find.byKey(const ValueKey('recipe_category_quick')));
      await tap(tester, find.text('Lưu nháp'));
      expect(service.saved!.categories, RecipeCategory.values.toSet());
      await tester.pump(const Duration(seconds: 4));
      router.pop();
      await tester.pumpAndSettle();
      router.push(PathRouter.recipeEditorScreen);
      await tester.pumpAndSettle();
      for (final category in RecipeCategory.values) {
        final chip = find.byKey(ValueKey('recipe_category_${category.id}'));
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        expect(tester.widget<AppFilterChip>(chip).selected, isTrue);
      }
      expect(tester.takeException(), isNull);
    },
  );

  Future<void> addIngredient(
    WidgetTester tester,
    String query,
    String id,
    String amount,
  ) async {
    await tap(tester, find.byKey(const ValueKey('recipe_add_ingredient_main')));
    await tester.enterText(
      find.byKey(const ValueKey('ingredient_search')),
      query,
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(ValueKey('ingredient_option_$id')));
    await tester.enterText(
      find.byKey(const ValueKey('ingredient_amount')),
      amount,
    );
    await tap(tester, find.byKey(const ValueKey('ingredient_confirm')));
  }

  Future<void> goIngredients(WidgetTester tester) async {
    picker.onPick = () async => recipeCoverFixture();
    await tap(tester, find.byKey(const ValueKey('recipe_cover_picker')));
    await tester.enterText(
      find.byKey(const ValueKey('recipe_title')),
      'Trứng chiên hành',
    );
    await tap(tester, find.byKey(const ValueKey('recipe_continue')));
  }

  testWidgets(
    'four stage author flow validates each stage, previews real data and submits',
    (tester) async {
      final router = createRouter();
      await open(tester, router);
      expect(find.text('Đăng món'), findsOneWidget);
      expect(find.textContaining('Admin'), findsNothing);
      expect(find.byType(TabBar), findsNothing);
      expect(find.byKey(const ValueKey('recipe_step_step_0')), findsNothing);
      await tap(tester, find.byKey(const ValueKey('recipe_continue')));
      expect(service.submitCalls, 0);
      expect(find.text('Thêm ảnh bìa cho món ăn.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('recipe_title')),
        'Trứng chiên',
      );
      await tester.enterText(find.byKey(const ValueKey('recipe_title')), '');
      await tester.pump();
      expect(find.text('Nhập tên món ăn.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('recipe_title')),
        'Trứng chiên hành',
      );
      await tester.enterText(
        find.byKey(const ValueKey('recipe_description')),
        'Món ngon cho bữa sáng.',
      );
      picker.onPick = () async => recipeCoverFixture();
      await tap(tester, find.byKey(const ValueKey('recipe_cover_picker')));
      expect(picker.pickCalls, 1);
      await tap(tester, find.byKey(const ValueKey('recipe_continue')));
      expect(find.byKey(const ValueKey('recipe_title')), findsNothing);
      await tap(tester, find.byKey(const ValueKey('recipe_continue')));
      expect(find.text('Thêm từ 1 đến 30 nguyên liệu.'), findsOneWidget);
      await addIngredient(tester, 'trung', 'egg', '2');
      await tap(tester, find.byKey(const ValueKey('recipe_continue')));
      await tap(tester, find.byKey(const ValueKey('recipe_continue')));
      expect(find.text('Mô tả cách thực hiện bước này.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('recipe_step_step_0')),
        'Chiên trứng đến khi chín.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('recipe_step_title_step_0')),
        'Chiên trứng',
      );
      await tester.enterText(
        find.byKey(const ValueKey('recipe_step_minutes_step_0')),
        '10',
      );
      await tap(tester, find.byKey(const ValueKey('recipe_continue')));
      expect(find.text('Trứng chiên hành'), findsOneWidget);
      expect(find.text('Món ngon cho bữa sáng.'), findsOneWidget);
      expect(find.text('Trứng gà'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Chiên trứng đến khi chín.'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Chiên trứng đến khi chín.'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('recipe_continue')));
      expect(service.submitCalls, 1);
      expect(service.submitted!.title, 'Trứng chiên hành');
      expect(service.submitted!.cover, isNotNull);
      expect(service.submitted!.description, 'Món ngon cho bữa sáng.');
      expect(service.submitted!.steps.single.minutes, '10');
      expect(find.text('Trang trước'), findsOneWidget);
      expect(find.text('Đã gửi công thức chờ duyệt.'), findsOneWidget);
      expect(find.text('Thành công'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('Thành công'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalog rows edit atomically, cancel preserves data and removing keeps next row',
    (tester) async {
      final router = createRouter();
      await open(tester, router);
      await goIngredients(tester);
      await addIngredient(tester, 'trung', 'egg', '2');
      await addIngredient(tester, 'ca chua', 'tomato', '1');
      await tap(tester, find.text('Cà chua'));
      await tester.enterText(
        find.byKey(const ValueKey('ingredient_amount')),
        '3',
      );
      await tap(tester, find.byTooltip('Đóng'));
      expect(find.text('1 quả'), findsOneWidget);
      await tap(tester, find.text('Cà chua'));
      await tester.enterText(
        find.byKey(const ValueKey('ingredient_amount')),
        '3',
      );
      await tap(tester, find.byKey(const ValueKey('ingredient_confirm')));
      expect(find.text('3 quả'), findsOneWidget);
      await tap(tester, find.byTooltip('Xóa Trứng gà'));
      expect(find.text('Trứng gà'), findsNothing);
      expect(find.text('Cà chua'), findsOneWidget);
      expect(find.text('3 quả'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'custom ingredient supports to taste and survives draft restore',
    (tester) async {
      final router = createRouter();
      await open(tester, router);
      await goIngredients(tester);
      await tap(
        tester,
        find.byKey(const ValueKey('recipe_add_ingredient_main')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('ingredient_search')),
        'Lá mắc mật',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('ingredient_custom')));
      await tap(tester, find.byType(SwitchListTile));
      await tester.enterText(
        find.byKey(const ValueKey('ingredient_note')),
        'Rửa sạch',
      );
      await tap(tester, find.byKey(const ValueKey('ingredient_confirm')));
      expect(find.text('Vừa đủ · Rửa sạch'), findsOneWidget);
      await tap(tester, find.text('Lưu nháp'));
      final item = service.saved!.ingredients.single;
      expect(item.ingredientId, isNull);
      expect(item.toTaste, isTrue);
      expect(item.amount, isNull);
      expect(item.unitId, isNull);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('Quay lại'));
      await tap(tester, find.byTooltip('Quay lại'));
      router.push(PathRouter.recipeEditorScreen);
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('recipe_continue')));
      expect(find.text('Lá mắc mật'), findsOneWidget);
      expect(find.text('Vừa đủ · Rửa sạch'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('partial draft persists after leaving and reopening editor', (
    tester,
  ) async {
    final router = createRouter();
    await open(tester, router);
    await tester.enterText(
      find.byKey(const ValueKey('recipe_title')),
      'Món nháp',
    );
    await tap(tester, find.text('Lưu nháp'));
    expect(service.saved!.title, 'Món nháp');
    expect(find.text('Đã lưu bản nháp.'), findsOneWidget);
    expect(find.text('Thành công'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(service.saved!.cover, isNull);
    await tap(tester, find.byTooltip('Quay lại'));
    expect(find.text('Rời màn hình?'), findsNothing);
    expect(find.text('Trang trước'), findsOneWidget);
    router.push(PathRouter.recipeEditorScreen);
    await tester.pumpAndSettle();
    expect(find.text('Món nháp'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'back confirms unsaved changes, cancel keeps form and discard leaves',
    (tester) async {
      final router = createRouter();
      await open(tester, router);
      await tester.enterText(
        find.byKey(const ValueKey('recipe_title')),
        'Chưa lưu',
      );
      await tap(tester, find.byTooltip('Quay lại'));
      expect(find.text('Rời màn hình?'), findsOneWidget);
      await tap(tester, find.text('Ở lại'));
      expect(find.text('Chưa lưu'), findsOneWidget);
      await tap(tester, find.byTooltip('Quay lại'));
      await tap(tester, find.text('Bỏ thay đổi'));
      expect(find.text('Trang trước'), findsOneWidget);
      expect(service.saved, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 800.0]) {
    testWidgets(
      'steps reorder with their fields and review can edit at width $width',
      (tester) async {
        service.saved = validRecipeDraft();
        await open(tester, createRouter(), width: width, scale: 1.5);
        tester.view.physicalSize = Size(width, 844);
        await tester.pumpAndSettle();
        await tap(tester, find.byKey(const ValueKey('recipe_continue')));
        await tap(tester, find.byKey(const ValueKey('recipe_continue')));
        final firstTitle = find.byKey(
          const ValueKey('recipe_step_title_step_0'),
        );
        await tester.scrollUntilVisible(
          firstTitle,
          120,
          scrollable: find
              .descendant(
                of: find.byType(RecipeEditorForm),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.enterText(firstTitle, 'Chuẩn bị');
        await tap(tester, find.text('Thêm bước'));
        final secondInstruction = find.byKey(
          const ValueKey('recipe_step_step_1'),
        );
        await tester.ensureVisible(secondInstruction);
        await tester.enterText(secondInstruction, 'Chiên vàng hai mặt.');
        await tap(tester, find.byTooltip('Tùy chọn bước 2'));
        await tap(tester, find.text('Chuyển bước 2 lên'));
        expect(
          tester
              .widget<TextFormField>(
                find.descendant(
                  of: secondInstruction,
                  matching: find.byType(TextFormField),
                  matchRoot: true,
                ),
              )
              .initialValue,
          'Chiên vàng hai mặt.',
        );
        await tap(tester, find.byKey(const ValueKey('recipe_continue')));
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('recipe_review_edit_instructions')),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tap(
          tester,
          find.byKey(const ValueKey('recipe_review_edit_instructions')),
        );
        await tester.scrollUntilVisible(
          firstTitle,
          120,
          scrollable: find
              .descendant(
                of: find.byType(RecipeEditorForm),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(
          tester
              .widget<TextFormField>(
                find.descendant(
                  of: firstTitle,
                  matching: find.byType(TextFormField),
                  matchRoot: true,
                ),
              )
              .initialValue,
          'Chuẩn bị',
        );
        expect(
          tester
              .widget<TextFormField>(
                find.descendant(
                  of: secondInstruction,
                  matching: find.byType(TextFormField),
                  matchRoot: true,
                ),
              )
              .initialValue,
          'Chiên vàng hai mặt.',
        );
        await tap(tester, find.byTooltip('Quay lại'));
        expect(find.text('Nguyên liệu & định lượng'), findsOneWidget);
        expect(find.text('Rời màn hình?'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ingredient sheet supports keyboard, units and large text at width $width',
      (tester) async {
        await open(tester, createRouter(), width: width, scale: 1.5);
        await goIngredients(tester);
        tester.view.physicalSize = Size(width, 820);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('recipe_add_ingredient_main')),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tap(
          tester,
          find.byKey(const ValueKey('recipe_add_ingredient_main')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('ingredient_search')),
          'thit bo',
        );
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        await tap(tester, find.byKey(const ValueKey('ingredient_option_beef')));
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tap(tester, find.byKey(const ValueKey('ingredient_confirm')));
        expect(
          find.text('Nhập lượng dùng là số nguyên từ 1 đến 100.000.'),
          findsOneWidget,
        );
        final amount = find.byKey(const ValueKey('ingredient_amount'));
        await tester.ensureVisible(amount);
        await tester.enterText(amount, '0,5');
        await tap(tester, find.byKey(const ValueKey('ingredient_confirm')));
        expect(
          find.text('Nhập lượng dùng là số nguyên từ 1 đến 100.000.'),
          findsOneWidget,
        );
        await tester.enterText(amount, '1');
        await tap(tester, find.byType(DropdownButtonFormField<IngredientUnit>));
        await tap(tester, find.text('kg').last);
        await tap(tester, find.byKey(const ValueKey('ingredient_confirm')));
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(find.text('1 kg'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('form remains scrollable with large text at width $width', (
      tester,
    ) async {
      await open(tester, createRouter(), width: width, scale: 1.5);
      await tap(tester, find.byKey(const ValueKey('recipe_continue')));
      for (var i = 0; i < 5; i++) {
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('profile add action opens recipe editor through app routing', (
    tester,
  ) async {
    final router = GoRouter(
      routes: appRouter.configuration.routes,
      initialLocation: PathRouter.homeScreen,
    );
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(router.dispose);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(host(router));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('nav_item_3')));
    await tap(tester, find.text('Đăng món'));
    expect(find.byType(RecipeEditorScreen), findsOneWidget);
    expect(find.text('Đăng món'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
