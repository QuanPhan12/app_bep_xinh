import 'package:app_bep_xinh/features/profile/widgets/profile_recipe_filters.dart';
import 'package:app_bep_xinh/features/profile/widgets/profile_recipe_tabs.dart';
import 'package:app_bep_xinh/features/auth/services/auth_service.dart';

import '../../support/auth_fake.dart';

import 'dart:async';

import 'package:app_bep_xinh/core/widgets/app_avatar.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:app_bep_xinh/core/widgets/app_sliver_app_bar.dart';
import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:app_bep_xinh/features/navigation/widgets/app_bottom_nav_bar.dart';
import 'package:app_bep_xinh/features/profile/widgets/profile_photo_grid.dart';
import 'package:app_bep_xinh/features/profile/models/profile_data.dart';
import 'package:app_bep_xinh/features/profile/screens/profile_screen.dart';
import 'package:app_bep_xinh/features/profile/screens/profile_edit_screen.dart';
import 'package:app_bep_xinh/features/profile/services/profile_service.dart';
import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:app_bep_xinh/features/settings/screens/settings_screen.dart';

import '../../support/mock_services.dart';
import '../../support/profile_fakes.dart';
import '../../support/recipe_detail_fakes.dart';
import '../../support/test_text_styles.dart';
import '../../support/kitchen_fakes.dart';

import 'package:app_bep_xinh/features/kitchen/services/kitchen_services.dart';
import 'package:app_bep_xinh/features/kitchen/models/kitchen_entry.dart';
import 'package:app_bep_xinh/features/profile/cubits/profile/profile_cubit.dart';
import 'package:app_bep_xinh/features/profile/widgets/profile_content.dart';

void main() {
  setUp(configureAuthenticatedTaps);
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

  GoRouter router({String location = PathRouter.profileScreen}) => GoRouter(
    routes: appRouter.configuration.routes,
    initialLocation: location,
  );
  Widget host(GoRouter route, {double scale = 1}) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthService>(
        create: (_) => StubAuthService(),
        dispose: (service) => (service as StubAuthService).dispose(),
      ),
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
    if (finder.evaluate().isEmpty) {
      final body = find
          .byWidgetPredicate(
            (w) =>
                w is Scrollable &&
                w.axisDirection == AxisDirection.down &&
                w.physics is! NeverScrollableScrollPhysics,
          )
          .last;
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: body,
        maxScrolls: 40,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'empty profile hides technical handle and filters, and creates first recipe',
    (tester) async {
      final original = accountFixture();
      final generated = UserProfile.fromJson({
        ...original.toJson(),
        'handle': 'bep_${original.id}',
      });
      service.onFetch = () async => ProfileData(
        account: generated,
        recipes: profileFixture().recipes,
        ownRecipeIds: {},
      );
      final route = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
          GoRoute(
            path: PathRouter.recipeEditorScreen,
            builder: (_, _) =>
                const Scaffold(body: Text('first_recipe_editor')),
          ),
        ],
      );
      await open(tester, route);
      expect(find.text('@${generated.handle}'), findsNothing);
      expect(find.byType(ProfileRecipeFilters), findsNothing);
      expect(find.text('Đăng món'), findsNothing);
      expect(find.text('Quản lý bài đăng'), findsNothing);
      await tap(tester, find.text('Đăng công thức đầu tiên'));
      expect(find.text('first_recipe_editor'), findsOneWidget);
      route.pop();
      await tester.pumpAndSettle();
      expect(service.reads, greaterThanOrEqualTo(2));
      expect(service.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('saved and recipe stats open their full collection', (
    tester,
  ) async {
    final route = router();
    await open(tester, route);
    final cubit = tester
        .element(find.byType(ProfileContent))
        .read<ProfileCubit>();
    cubit.selectFilter(ProfileRecipeFilter.from30);
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('profile_stat_saved')));
    expect(cubit.state.tab, ProfileTab.saved);
    expect(cubit.state.filter, ProfileRecipeFilter.all);
    await tap(tester, find.byKey(const ValueKey('profile_stat_recipes')));
    expect(cubit.state.tab, ProfileTab.recipes);
    expect(find.text('@${service.account.handle}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty filtered results retain filters and can clear them', (
    tester,
  ) async {
    final recipe = profileFixture().ownRecipes.first;
    service.onFetch = () async => ProfileData(
      account: service.account,
      recipes: [recipe],
      ownRecipeIds: {recipe.id},
    );
    await open(tester, router());
    final cubit = tester
        .element(find.byType(ProfileContent))
        .read<ProfileCubit>();
    cubit.selectFilter(
      recipe.cookTimeMinutes < 30
          ? ProfileRecipeFilter.from30
          : ProfileRecipeFilter.under30,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProfileRecipeFilters), findsOneWidget);
    expect(find.text('Đăng công thức đầu tiên'), findsNothing);
    await tap(tester, find.text('Xóa bộ lọc'));
    expect(cubit.state.filter, ProfileRecipeFilter.all);
    expect(find.byType(ProfilePhotoGrid), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'profile initializes with the real KitchenScope and journal count',
    (tester) async {
      final kitchen = kitchenFixture();
      final route = router();
      addTearDown(route.dispose);
      addTearDown(() => disposeKitchen(kitchen));
      const recipe = RecipeRef(
        id: 'r_test',
        title: 'Món thử',
        authorId: 'author',
      );
      for (var index = 0; index < 2; index++) {
        await kitchen.journal.save(
          CookingLog(
            id: 'session_$index',
            recipe: recipe,
            day: '2026-11-16',
            servings: 2,
            note: '',
          ),
        );
      }
      await tester.pumpWidget(
        KitchenScope(services: kitchen, child: host(route)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Mai Anh'), findsOneWidget);
      final context = tester.element(find.byType(ProfileContent));
      expect(context.read<ProfileCubit>().state.cookingLogCount, 2);
      await tap(tester, find.byKey(const ValueKey('profile_stat_journal')));
      expect(
        route.routerDelegate.currentConfiguration.last.matchedLocation,
        '/kitchen/journal',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('profile photo grid opens correct recipe and syncs saved tab', (
    tester,
  ) async {
    final route = router();
    await open(tester, route, height: 1600);
    expect(find.byType(AppSliverAppBar), findsOneWidget);
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(find.byTooltip('Cài đặt'), findsOneWidget);
    expect(find.text('Mai Anh'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is AppAvatar && widget.name == 'Mai Anh',
      ),
      findsOneWidget,
    );
    expect(find.text('MA'), findsOneWidget);
    expect(find.text('Đăng món'), findsOneWidget);
    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
    expect(find.text('Cài đặt'), findsNothing);
    expect(find.byIcon(PhosphorIconsRegular.gearSix), findsOneWidget);
    expect(find.byType(ProfilePhotoGrid), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            profileFixture().ownRecipes
                .map((item) => item.title)
                .contains(widget.message),
      ),
      findsNWidgets(2),
    );
    await tap(
      tester,
      find.descendant(
        of: find.byType(ProfileRecipeTabs),
        matching: find.text('Đã lưu'),
      ),
    );
    expect(find.byTooltip('Salad ức gà sốt mè rang'), findsOneWidget);
    await favorites.setFavorite('salad_uc_ga_me_rang', false);
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có món đã lưu'), findsOneWidget);
    await favorites.setFavorite('bo_ne_tieu_den', true);
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('Bò né sốt tiêu đen bánh mì'));
    expect(
      route.routerDelegate.currentConfiguration.last.matchedLocation,
      '/recipe/bo_ne_tieu_den',
    );
    await tap(tester, find.byTooltip('Quay lại'));
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byTooltip('Bò né sốt tiêu đen bánh mì'), findsOneWidget);
  });

  testWidgets(
    'time filter updates the collection and keeps saved tab navigation usable',
    (tester) async {
      await open(tester, router(), height: 1600);
      await tap(tester, find.text('Từ 30 phút'));
      expect(find.text('Không có món phù hợp'), findsOneWidget);
      expect(find.byType(ProfilePhotoGrid), findsNothing);
      await tap(tester, find.text('Dưới 30 phút'));
      expect(find.byType(ProfilePhotoGrid), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              profileFixture().ownRecipes
                  .map((item) => item.title)
                  .contains(widget.message),
        ),
        findsNWidgets(2),
      );
      await tap(tester, find.text('Tất cả'));
      await tap(
        tester,
        find.descendant(
          of: find.byType(ProfileRecipeTabs),
          matching: find.text('Đã lưu'),
        ),
      );
      expect(find.byTooltip('Salad ức gà sốt mè rang'), findsOneWidget);
      await tap(tester, find.byTooltip('Cài đặt'));
      await tap(tester, find.byTooltip('Quay lại'));
      expect(find.byTooltip('Salad ức gà sốt mè rang'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'settings opens above shell, visibility updates profile and back retains tab',
    (tester) async {
      final route = router();
      await open(tester, route);
      await tap(
        tester,
        find.descendant(
          of: find.byType(ProfileRecipeTabs),
          matching: find.text('Đã lưu'),
        ),
      );
      await tap(tester, find.byTooltip('Cài đặt'));
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);
      await tap(tester, find.byKey(const ValueKey('settings_show_bio')));
      expect(service.account.showBio, isFalse);
      await tap(tester, find.byTooltip('Quay lại'));
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text(service.account.bio), findsNothing);
      expect(find.byTooltip('Salad ức gà sốt mè rang'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'editing validates clearing and retyping, saves and shows custom success',
    (tester) async {
      final route = router();
      await open(tester, route);
      await tap(tester, find.byTooltip('Cài đặt'));
      await tap(tester, find.text('Chỉnh sửa hồ sơ'));
      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        route.routerDelegate.currentConfiguration.last.matchedLocation,
        PathRouter.profileEditScreen,
      );
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
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Đã cập nhật hồ sơ.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tap(tester, find.byTooltip('Quay lại'));
      expect(find.text('Nấu những món mình yêu.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'edit deep link retries load and returns to settings without a write',
    (tester) async {
      service.onFetchAccount = () async => throw StateError('offline');
      await open(tester, router(location: PathRouter.profileEditScreen));
      expect(
        find.text('Không tải được hồ sơ. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(find.byType(AppBottomNavBar), findsNothing);
      expect(find.byKey(const ValueKey('profile_name')), findsNothing);
      service.onFetchAccount = null;
      await tap(tester, find.text('Thử lại'));
      expect(
        tester
            .widget<TextFormField>(
              find.descendant(
                of: find.byKey(const ValueKey('profile_name')),
                matching: find.byType(TextFormField),
                matchRoot: true,
              ),
            )
            .initialValue,
        service.account.name,
      );
      await tap(tester, find.byTooltip('Quay lại'));
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(service.writes, 0);
    },
  );

  testWidgets(
    'edit blocks back during saving and keeps the form after a failed write',
    (tester) async {
      final pending = Completer<void>();
      service.onWrite = () => pending.future;
      await open(tester, router(location: PathRouter.profileEditScreen));
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pump();
      expect(
        tester
            .widget<AppSliverAppBar>(find.byType(AppSliverAppBar))
            .backEnabled,
        isFalse,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(ProfileEditScreen), findsOneWidget);
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(
        find.text('Chưa cập nhật được hồ sơ. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(find.byType(ProfileEditScreen), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.descendant(
                of: find.byKey(const ValueKey('profile_name')),
                matching: find.byType(TextFormField),
                matchRoot: true,
              ),
            )
            .initialValue,
        service.account.name,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      service.onWrite = null;
      await tap(tester, find.text('Lưu thay đổi'));
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(service.writes, 2);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('back protects unsaved profile and discard never writes', (
    tester,
  ) async {
    await open(tester, router(location: PathRouter.profileEditScreen));
    final name = find.byKey(const ValueKey('profile_name'));
    await tester.enterText(name, 'Bản nháp hồ sơ');
    await tap(tester, find.byTooltip('Quay lại'));
    expect(find.text('Bỏ thay đổi hồ sơ?'), findsOneWidget);
    await tap(tester, find.text('Ở lại'));
    expect(find.text('Bản nháp hồ sơ'), findsOneWidget);
    expect(service.writes, 0);
    // Back hệ thống cũng phải bảo vệ cùng bản nháp.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi hồ sơ?'), findsOneWidget);
    await tap(tester, find.text('Bỏ thay đổi'));
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(service.writes, 0);
    expect(tester.takeException(), isNull);
  });

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
        await tap(tester, find.byTooltip('Cài đặt'));
        await tap(tester, find.text('Chỉnh sửa hồ sơ'));
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
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        await tap(tester, find.byTooltip('Quay lại'));
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
