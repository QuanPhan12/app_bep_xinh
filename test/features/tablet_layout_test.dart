import 'package:app_bep_xinh/features/profile/models/profile_data.dart';
import 'package:app_bep_xinh/core/widgets/app_tabs.dart';
import 'package:app_bep_xinh/features/home/widgets/home_feed_view.dart';

import '../support/kitchen_fakes.dart';

import 'package:app_bep_xinh/features/cooking_timers/services/cooking_timer_service.dart';

import 'package:app_bep_xinh/features/kitchen/services/kitchen_services.dart';
import 'package:app_bep_xinh/features/profile/widgets/profile_content.dart';
import 'package:app_bep_xinh/features/profile/cubits/profile/profile_cubit.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/core/themes/app_theme_cubit.dart';
import 'package:app_bep_xinh/features/auth/services/auth_service.dart';
import 'package:app_bep_xinh/features/auth/models/account_access.dart';
import 'package:app_bep_xinh/features/messages/services/message_repository.dart';
import 'package:app_bep_xinh/features/messages/services/chat_image_service.dart';
import 'package:app_bep_xinh/features/notifications/services/notification_repository.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_submission_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/models/recipe_submission.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_image.dart';
import 'package:app_bep_xinh/features/recipe_editor/widgets/recipe_ingredient_sheet.dart';
import 'package:app_bep_xinh/features/notifications/widgets/notification_details.dart';
import 'package:app_bep_xinh/features/fridge/widgets/fridge_ingredient_sheet.dart';
import 'package:app_bep_xinh/features/fridge/widgets/fridge_content.dart';
import 'package:app_bep_xinh/core/widgets/app_adaptive_columns.dart';

import '../support/auth_fake.dart';
import '../support/communication_fakes.dart';

import 'package:app_bep_xinh/features/recipe_search/services/recipe_search_service.dart';

import '../support/recipe_search_fakes.dart';

import 'package:app_bep_xinh/features/recipe_editor/screens/recipe_editor_screen.dart';

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

class _AuditThemePreference implements ThemePreference {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String value) async {}
}

class _TabletAuthService extends StubAuthService
    implements AccountSessionAccess {
  @override
  AccountAccess get accountAccess =>
      const AccountAccess(AccountAccessStatus.locked);
  @override
  Future<void> retryAccountAccess() async {}
}

// Audit layout dùng kho rỗng; vòng tick thực được kiểm thử ở cooking timer tests.
class _LayoutTimers extends CookingTimerService {
  _LayoutTimers()
    : super(
        storage: MemoryKitchenStorage(),
        storageKey: 'layout',
        checkSession: () {},
      );
  @override
  Future<void> load() async {}
}

class _TabletSubmissions implements RecipeSubmissionService {
  @override
  Future<void> changeVisibility(
    RecipeSubmission expected,
    RecipeVisibilityAction action,
  ) async {}
  @override
  Future<List<RecipeSubmission>> fetchOwn() async => [
    for (final status in RecipeSubmissionStatus.values)
      RecipeSubmission(
        id: status.name,
        title: 'Công thức thử nghiệm có tên dài trên máy tính bảng',
        cover: const RecipeImage.asset(
          id: 'photo',
          assetPath: 'assets/images/fridge_tofu_tomato.webp',
        ),
        status: status,
        submittedAt: DateTime.utc(2026, 11, 16),
        reviewReason: status == RecipeSubmissionStatus.rejected
            ? 'Cần bổ sung hướng dẫn chi tiết.'
            : null,
      ),
  ];
  @override
  Future<void> createRevision(String id) async {}
}

void main() {
  setUp(configureAuthenticatedTaps);
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
    bool dark = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: appRouter.configuration.routes,
      initialLocation: path,
    );
    final kitchen = kitchenFixture(timers: _LayoutTimers());
    addTearDown(() => disposeKitchen(kitchen));
    final favorites = StubRecipeFavoritesService();
    final profile = StubProfileService();
    if (const bool.fromEnvironment('UI_CAPTURE_PROFILE_EMPTY')) {
      final account = accountFixture();
      profile.onFetch = () async => ProfileData(
        account: UserProfile.fromJson({
          ...account.toJson(),
          'handle': 'bep_${account.id}',
        }),
        recipes: profileFixture().recipes,
        ownRecipeIds: {},
      );
    }
    final publicProfiles = StubPublicProfileService();
    final messages = FakeMessageRepository();
    final notifications = FakeNotificationRepository();
    addTearDown(router.dispose);
    addTearDown(favorites.dispose);
    addTearDown(profile.dispose);
    addTearDown(publicProfiles.dispose);
    addTearDown(messages.dispose);
    addTearDown(notifications.dispose);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          if (const bool.fromEnvironment('UI_CAPTURE'))
            RepositoryProvider<AppThemeCubit>(
              create: (_) =>
                  AppThemeCubit(_AuditThemePreference())
                    ..select(dark ? ThemeMode.dark : ThemeMode.light),
              dispose: (cubit) {
                cubit.close();
              },
            ),
          RepositoryProvider<AuthService>(
            create: (_) => _TabletAuthService(),
            dispose: (service) => (service as StubAuthService).dispose(),
          ),
          RepositoryProvider<HomeService>.value(value: StubHomeService()),
          RepositoryProvider<MessageRepository>.value(value: messages),
          RepositoryProvider<ChatImageService>.value(
            value: FakeChatImageService(),
          ),
          RepositoryProvider<NotificationRepository>.value(
            value: notifications,
          ),
          RepositoryProvider<RecipeSubmissionService>.value(
            value: _TabletSubmissions(),
          ),
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
        child: RepaintBoundary(
          key: const ValueKey('ui_audit_capture'),
          child: MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: Builder(
                builder: (context) => AppTheme.builder(
                  context,
                  KitchenScope(services: kitchen, child: child!),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  for (final size in [const Size(390, 844), const Size(1024, 768)]) {
    testWidgets(
      'four destinations and profile creation preserve shell at $size',
      (tester) async {
        final router = await open(tester, size, path: '/home');
        for (var i = 0; i < 4; i++) {
          AppTapHandler.resetLock();
          final target = size.width < 600
              ? find.byKey(ValueKey('nav_item_$i'))
              : find.byTooltip(
                  'Đi đến ${['Trang chủ', 'Tủ lạnh', 'Bếp của tôi', 'Cá nhân'][i]}',
                );
          await tester.tap(target);
          await tester.pumpAndSettle();
          expect(
            router.routerDelegate.currentConfiguration.last.matchedLocation,
            ['/home', '/fridge', '/kitchen', '/profile'][i],
          );
          expect(tester.takeException(), isNull);
        }
        await tester.ensureVisible(find.text('Đăng món'));
        await tester.tap(find.text('Đăng món'));
        await tester.pumpAndSettle();
        expect(find.byType(RecipeEditorScreen), findsOneWidget);
        await tester.tap(find.byTooltip('Quay lại'));
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.last.matchedLocation,
          '/profile',
        );
        router.go('/profile?tab=saved');
        await tester.pumpAndSettle();
        final cubit = tester
            .element(find.byType(ProfileContent))
            .read<ProfileCubit>();
        expect(cubit.state.tab, ProfileTab.saved);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final size in [
    const Size(600, 960),
    const Size(599, 900),
    const Size(800, 1100),
    const Size(1024, 768),
    const Size(1024, 600),
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
          '/profile/edit',
          '/profile/submissions',
          '/account-access',
          '/notifications',
          '/messages',
          '/messages/new',
          PathRouter.conversation(FakeMessageRepository.conversationId),
          '/recipe/bo_ne_tieu_den',
          '/recipes/new',
          '/recipes/search',
        ]) {
          router.go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$path at $size');
          for (var scroll = 0; scroll < 3; scroll++) {
            final scrollable = find.byWidgetPredicate(
              (widget) =>
                  widget is CustomScrollView &&
                  widget.physics is! NeverScrollableScrollPhysics,
            );
            if (scrollable.evaluate().isNotEmpty) {
              await tester.drag(scrollable.last, const Offset(0, -300));
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
    'wide fridge separates inventory and suggestions while recipe keeps cooking panes',
    (tester) async {
      final router = await open(tester, const Size(1024, 768), path: '/fridge');
      expect(
        tester.getTopLeft(find.byType(FridgeRecipeSuggestions)).dx,
        greaterThan(tester.getTopRight(find.byType(FridgeInventoryCard)).dx),
      );
      expect(
        (tester.getTopLeft(find.byType(FridgeRecipeSuggestions)).dy -
                tester.getTopLeft(find.byType(FridgeInventoryCard)).dy)
            .abs(),
        lessThan(1),
      );
      router.go('/recipe/bo_ne_tieu_den');
      await tester.pumpAndSettle();
      expect(
        tester
            .getTopLeft(
              find.byWidgetPredicate((widget) => widget is AppTabs).first,
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
          find.text(entry.value).last,
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

  testWidgets(
    'adaptive columns preserve field selection and focus on rotation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1024, 768);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AppAdaptiveColumns(
                primary: TextField(),
                secondary: Text('Cột phụ'),
              ),
            ),
          ),
        ),
      );
      final field = find.byType(TextField);
      await tester.enterText(field, 'Nội dung đang soạn');
      final original = tester.element(field);
      final controller = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller;
      controller.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 7,
      );
      for (final size in [const Size(768, 1024), const Size(1024, 768)]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(tester.element(field), same(original));
        expect(find.text('Nội dung đang soạn'), findsOneWidget);
        expect(tester.testTextInput.isVisible, isTrue);
        expect(
          tester.widget<EditableText>(find.byType(EditableText)).controller,
          same(controller),
        );
        expect(
          controller.selection,
          const TextSelection(baseOffset: 2, extentOffset: 7),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('tablet search scrolls results above a landscape keyboard', (
    tester,
  ) async {
    await open(
      tester,
      const Size(1024, 600),
      path: '/recipes/search',
      scale: 1.5,
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final field = find.byType(TextFormField).first;
    await tester.enterText(field, 'bo');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('bo'), findsOneWidget);
    final content = find.byWidgetPredicate(
      (widget) =>
          widget is CustomScrollView &&
          widget.physics is! NeverScrollableScrollPhysics,
    );
    await tester.drag(content, const Offset(0, -450));
    await tester.pumpAndSettle();
    final scroll = tester.state<ScrollableState>(
      find.descendant(of: content, matching: find.byType(Scrollable)).first,
    );
    expect(scroll.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(390, 844),
    const Size(600, 960),
    const Size(1024, 600),
  ]) {
    testWidgets('ingredient pickers and notifications adapt at $size', (
      tester,
    ) async {
      final router = await open(tester, size, path: '/recipes/new', scale: 1.5);
      final editorContext = tester.element(find.byType(RecipeEditorForm));
      final ingredient = showRecipeIngredientSheet(editorContext);
      await tester.pumpAndSettle();
      expect(
        find.byType(Dialog),
        size.width >= 600 ? findsOneWidget : findsNothing,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byTooltip('Đóng'))).pop();
      await tester.pumpAndSettle();
      await ingredient;
      tester.view.viewInsets = const FakeViewPadding();
      router.go('/fridge');
      await tester.pumpAndSettle();
      final fridgeContext = tester.element(find.byType(FridgeContent));
      final fridge = showFridgeIngredientSheet(fridgeContext);
      await tester.pumpAndSettle();
      expect(
        find.byType(Dialog),
        size.width >= 600 ? findsOneWidget : findsNothing,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byTooltip('Đóng bảng nguyên liệu')))
          .pop();
      await tester.pumpAndSettle();
      await fridge;
      tester.view.viewInsets = const FakeViewPadding();
      final notice = showNotificationDetails(
        fridgeContext,
        item:
            (fridgeContext.read<NotificationRepository>()
                    as FakeNotificationRepository)
                .items
                .first,
        onViewRecipe: () {},
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(Dialog),
        size.width >= 600 ? findsOneWidget : findsNothing,
      );
      expect(find.text('Xem công thức'), findsOneWidget);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byTooltip('Đóng thông báo'))).pop();
      await tester.pumpAndSettle();
      await notice;
    });
  }

  testWidgets(
    'input screens fit landscape tablet with keyboard and keep drafts',
    (tester) async {
      final router = await open(tester, const Size(1024, 600), scale: 1.5);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      for (final path in [
        '/login',
        '/register',
        '/forgot-password',
        '/profile/edit',
        '/recipes/new',
        '/messages/new',
        PathRouter.conversation(FakeMessageRepository.conversationId),
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
        final fields = find.byType(TextFormField);
        for (
          var attempt = 0;
          fields.evaluate().isEmpty && attempt < 15;
          attempt++
        ) {
          await tester.drag(
            find
                .byWidgetPredicate(
                  (widget) =>
                      widget is CustomScrollView &&
                      widget.physics is! NeverScrollableScrollPhysics,
                )
                .last,
            const Offset(0, -120),
          );
          await tester.pumpAndSettle();
        }
        expect(fields, findsWidgets, reason: path);
        final field = fields.first;
        await tester.ensureVisible(field);
        await tester.enterText(field, 'Bản nháp tablet');
        await tester.pumpAndSettle();
        tester.view.physicalSize = const Size(768, 1024);
        await tester.pumpAndSettle();
        expect(find.text('Bản nháp tablet'), findsOneWidget, reason: path);
        tester.view.physicalSize = const Size(1024, 600);
        await tester.pumpAndSettle();
        expect(find.text('Bản nháp tablet'), findsOneWidget, reason: path);
        expect(tester.takeException(), isNull, reason: path);
      }
    },
  );

  for (final size in [const Size(390, 844), const Size(1024, 768)]) {
    testWidgets('main flows remain usable with 200 percent text at $size', (
      tester,
    ) async {
      final router = await open(tester, size, scale: 2);
      for (final path in [
        '/login',
        '/register',
        '/forgot-password',
        '/home',
        '/fridge',
        '/kitchen',
        '/kitchen/meal-plan',
        '/kitchen/pantry',
        '/kitchen/collections',
        '/kitchen/journal',
        '/kitchen/timers',
        '/kitchen/offline',
        '/kitchen/following',
        '/kitchen/following/feed',
        '/cart',
        '/profile',
        '/settings',
        '/profile/edit',
        '/profile/submissions',
        '/recipes/search',
        '/recipe/bo_ne_tieu_den',
        '/recipes/new',
        '/notifications',
        '/messages',
        '/messages/new',
        PathRouter.conversation(FakeMessageRepository.conversationId),
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
        final scroll = find.byWidgetPredicate(
          (widget) =>
              widget is CustomScrollView &&
              widget.physics is! NeverScrollableScrollPhysics,
        );
        if (scroll.evaluate().isNotEmpty) {
          await tester.drag(scroll.first, const Offset(0, -300));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull, reason: '$path after scrolling');
      }
    });
  }

  for (final size in [
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1280, 800),
  ]) {
    testWidgets('dark routes and resizing preserve content at $size', (
      tester,
    ) async {
      final router = await open(tester, size, dark: true, scale: 1.5);
      for (final path in [
        '/home',
        '/fridge',
        '/kitchen',
        '/kitchen/meal-plan',
        '/kitchen/pantry',
        '/kitchen/collections',
        '/kitchen/journal',
        '/kitchen/timers',
        '/kitchen/offline',
        '/kitchen/following',
        '/kitchen/following/feed',
        '/cart',
        '/profile',
        '/users/linh_nguyen',
        '/settings',
        '/login',
        '/register',
        '/forgot-password',
        '/recipes/search',
        '/recipe/bo_ne_tieu_den',
        '/recipes/new',
        '/notifications',
        '/messages',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
        final scaffold = find.byType(Scaffold).last;
        expect(
          Theme.of(tester.element(scaffold)).brightness,
          Brightness.dark,
          reason: path,
        );
      }
    });
  }

  for (final dark in [false, true]) {
    testWidgets(
      'Home shows all recipes without feed tabs and the photo is visible early, dark=$dark',
      (tester) async {
        tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
        addTearDown(tester.view.resetPadding);
        final router = await open(
          tester,
          const Size(390, 844),
          path: '/home',
          dark: dark,
        );
        final post = find.byType(HomeRecipePost).first;
        final photo = find
            .descendant(of: post, matching: find.byType(FeedRecipeImage))
            .first;
        final top = tester.getTopLeft(photo).dy;
        expect(
          top,
          lessThan(500),
          reason:
              'Người dùng phải thấy ảnh món đầu tiên trong màn hình ban đầu',
        );
        debugPrint('Home first feed photo top: $top logical px; dark=$dark');
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(const ValueKey('home_category_cat_all')),
              )
              .selected,
          true,
        );
        expect(find.text('Mới nhất'), findsNothing);
        expect(find.text('Theo dõi'), findsNothing);
        expect(
          router.routerDelegate.currentConfiguration.last.matchedLocation,
          '/home',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('capture app UI audit', (tester) async {
    final font = FontLoader('UiAudit')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/be_vietnam_pro/BeVietnamPro-Regular.ttf')
                .readAsBytesSync(),
          ),
        ),
      );
    await font.load();
    for (final family in ['BeVietnamPro', 'Be Vietnam Pro']) {
      final actualFont = FontLoader(family);
      for (final weight in [
        'Regular',
        'Medium',
        'SemiBold',
        'Bold',
        'ExtraBold',
      ]) {
        actualFont.addFont(
          Future.value(
            ByteData.sublistView(
              File('assets/fonts/be_vietnam_pro/BeVietnamPro-$weight.ttf')
                  .readAsBytesSync(),
            ),
          ),
        );
      }
      await actualFont.load();
    }

    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    AppTextStyles.titleLarge = AppTextStyles.titleLarge.copyWith(
      fontFamily: 'UiAudit',
    );
    AppTextStyles.titleMedium = AppTextStyles.titleMedium.copyWith(
      fontFamily: 'UiAudit',
    );
    AppTextStyles.titleSmall = AppTextStyles.titleSmall.copyWith(
      fontFamily: 'UiAudit',
    );
    AppTextStyles.headlineMedium = AppTextStyles.headlineMedium.copyWith(
      fontFamily: 'UiAudit',
    );
    AppTextStyles.headlineSmall = AppTextStyles.headlineSmall.copyWith(
      fontFamily: 'UiAudit',
    );
    AppTextStyles.bodyMedium = AppTextStyles.bodyMedium.copyWith(
      fontFamily: 'UiAudit',
    );
    AppTextStyles.bodySmall = AppTextStyles.bodySmall.copyWith(
      fontFamily: 'UiAudit',
    );
    AppTextStyles.labelLarge = AppTextStyles.labelLarge.copyWith(
      fontFamily: 'UiAudit',
    );
    AppTextStyles.labelMedium = AppTextStyles.labelMedium.copyWith(
      fontFamily: 'UiAudit',
    );
    AppTextStyles.labelSmall = AppTextStyles.labelSmall.copyWith(
      fontFamily: 'UiAudit',
    );
    AppTextStyles.metaText = AppTextStyles.metaText.copyWith(
      fontFamily: 'UiAudit',
    );
    AppTextStyles.primaryButton = AppTextStyles.primaryButton.copyWith(
      fontFamily: 'UiAudit',
    );
    for (final entry in [
      ('PhosphorRegular', 'Phosphor.ttf'),
      ('PhosphorBold', 'Phosphor-Bold.ttf'),
      ('PhosphorFill', 'Phosphor-Fill.ttf'),
    ]) {
      await (FontLoader('packages/phosphoricons_flutter/${entry.$1}')..addFont(
            rootBundle.load(
              'packages/phosphoricons_flutter/lib/fonts/${entry.$2}',
            ),
          ))
          .load();
    }
    const stage = String.fromEnvironment(
      'UI_CAPTURE_STAGE',
      defaultValue: 'after',
    );
    for (final size in [
      const Size(390, 844),
      const Size(800, 1100),
      const Size(1024, 768),
    ]) {
      final router = await open(
        tester,
        size,
        dark: const String.fromEnvironment('UI_CAPTURE_THEME') == 'dark',
      );
      for (final path in [
        '/home',
        '/fridge',
        '/kitchen',
        '/kitchen/meal-plan',
        '/kitchen/pantry',
        '/kitchen/collections',
        '/kitchen/journal',
        '/kitchen/timers',
        '/kitchen/offline',
        '/kitchen/following',
        '/kitchen/following/feed',
        '/cart',
        '/profile',
        '/users/linh_nguyen',
        '/settings',
        '/profile/edit',
        '/profile/submissions',
        '/login',
        '/register',
        '/forgot-password',
        '/account-access',
        '/recipes/search',
        '/recipe/bo_ne_tieu_den',
        '/recipes/new',
        '/notifications',
        '/messages',
        '/messages/new',
        PathRouter.conversation(FakeMessageRepository.conversationId),
      ]) {
        if (const bool.fromEnvironment('UI_CAPTURE_PROFILE_ONLY') &&
            path != '/profile') {
          continue;
        }
        const captureRoute = String.fromEnvironment('UI_CAPTURE_ROUTE');
        if (captureRoute.isNotEmpty && path != captureRoute) continue;
        if (const bool.fromEnvironment('UI_CAPTURE_HOME_ONLY') &&
            path != '/home' &&
            path != '/kitchen/following/feed') {
          continue;
        }
        router.go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('ui_audit_capture')),
        );
        for (final element in find.byType(Image).evaluate()) {
          final provider = (element.widget as Image).image;
          if (provider is AssetImage || provider is ResizeImage) {
            await tester.runAsync(
              () => precacheImage(provider, element, onError: (_, _) {}),
            );
          }
        }
        await tester.pumpAndSettle();
        final name = path.startsWith('/messages/') && path != '/messages/new'
            ? 'conversation'
            : path.replaceAll('/', '_');
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'build/ui_ux/$stage/${size.width.toInt()}x${size.height.toInt()}/$name.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  }, skip: !const bool.fromEnvironment('UI_CAPTURE'));

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
    for (final size in [
      const Size(1100, 800),
      const Size(599, 900),
      const Size(600, 960),
      const Size(390, 844),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(find.text('Đã chuẩn bị 4 trên 8 món'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
