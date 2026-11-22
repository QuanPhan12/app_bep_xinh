import '../../support/auth_fake.dart';

import 'dart:async';

import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/tap/tap.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:app_bep_xinh/core/widgets/app_skeleton.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';
import 'package:app_bep_xinh/features/profile/models/public_profile_data.dart';
import 'package:app_bep_xinh/features/profile/screens/public_profile_screen.dart';
import 'package:app_bep_xinh/features/profile/services/profile_service.dart';
import 'package:app_bep_xinh/features/profile/services/public_profile_service.dart';
import 'package:app_bep_xinh/features/recipe_detail/cubits/recipe_detail/recipe_detail_cubit.dart';
import 'package:app_bep_xinh/features/recipe_detail/models/recipe_detail.dart';
import 'package:app_bep_xinh/features/recipe_detail/screens/recipe_detail_screen.dart';
import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';
import 'package:app_bep_xinh/features/recipe_detail/widgets/recipe_detail_content.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/mock_services.dart';
import '../../support/profile_fakes.dart';
import '../../support/public_profile_fakes.dart';
import '../../support/recipe_detail_fakes.dart';
import '../../support/test_text_styles.dart';

void main() {
  setUp(configureAuthenticatedTaps);
  setUpAll(configureTestTextStyles);
  setUp(AppTapHandler.resetLock);
  late StubPublicProfileService profiles;
  late StubProfileService account;
  late StubRecipeFavoritesService favorites;
  late StubRecipeDetailService details;
  setUp(() {
    profiles = StubPublicProfileService();
    account = StubProfileService();
    favorites = StubRecipeFavoritesService();
    details = StubRecipeDetailService();
  });
  tearDown(() async {
    await profiles.dispose();
    await account.dispose();
    await favorites.dispose();
  });

  Future<GoRouter> open(
    WidgetTester tester,
    String path, {
    double width = 390,
    double scale = 1,
    bool settle = true,
  }) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: appRouter.configuration.routes,
      initialLocation: path,
    );
    addTearDown(router.dispose);
    addTearDown(() async {
      AppMessenger.hide();
      await tester.pumpWidget(const SizedBox.shrink());
    });
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<PublicProfileService>.value(value: profiles),
          RepositoryProvider<ProfileService>.value(value: account),
          RepositoryProvider<RecipeFavoritesService>.value(value: favorites),
          RepositoryProvider<RecipeDetailService>.value(value: details),
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
    if (settle) await tester.pumpAndSettle();
    return router;
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
    'recipe author opens the right public profile, its recipe and back preserves the original detail',
    (tester) async {
      final router = await open(tester, '/recipe/salad_uc_ga_me_rang');
      final original = tester
          .element(find.byType(RecipeDetailContent))
          .read<RecipeDetailCubit>();
      await tap(tester, find.bySemanticsLabel('Tăng khẩu phần'));
      await tap(
        tester,
        find.byKey(const ValueKey('detail_ingredient_chicken')),
      );
      final checked = original.state.checkedIngredients;
      expect(find.text('Linh Nguyễn'), findsOneWidget);
      expect(find.text('@linh.vao.bep'), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('recipe_author_profile')));
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/users/linh_nguyen',
      );
      expect(find.byType(PublicProfileScreen), findsOneWidget);
      expect(find.text('Linh Nguyễn'), findsOneWidget);
      expect(find.text('Công thức đã chia sẻ (3)'), findsOneWidget);
      expect(find.text('Sửa hồ sơ'), findsNothing);
      expect(find.byTooltip('Cài đặt'), findsNothing);
      expect(find.text('Đã lưu'), findsNothing);
      expect(find.byType(SegmentedButton), findsNothing);
      await tap(tester, find.byTooltip('Đậu hũ sốt cà chua'));
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/recipe/tofu_tomato',
      );
      expect(find.byType(RecipeDetailScreen), findsOneWidget);
      await tap(tester, find.byTooltip('Quay lại'));
      expect(find.byType(PublicProfileScreen), findsOneWidget);
      await tap(tester, find.byTooltip('Quay lại'));
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/recipe/salad_uc_ga_me_rang',
      );
      expect(
        identical(
          tester
              .element(find.byType(RecipeDetailContent))
              .read<RecipeDetailCubit>(),
          original,
        ),
        isTrue,
      );
      expect(original.state.servings, 3);
      expect(original.state.checkedIngredients, checked);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'loading, retry and not found do not show the current private account',
    (tester) async {
      final pending = Completer<PublicProfileData>();
      profiles.onFetch = (_) => pending.future;
      final router = await open(tester, '/users/linh_nguyen', settle: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AppSkeleton), findsOneWidget);
      pending.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không tải được hồ sơ. Vui lòng thử lại.'),
        findsOneWidget,
      );
      profiles.onFetch = null;
      await tap(tester, find.text('Thử lại'));
      expect(find.text('Linh Nguyễn'), findsOneWidget);
      router.go('/users/missing');
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy hồ sơ này.'), findsOneWidget);
      expect(find.text('Mai Anh'), findsNothing);
      expect(find.text('Sửa hồ sơ'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'changing profile ids ignores a late response from the previous user',
    (tester) async {
      final pending = Completer<PublicProfileData>();
      profiles.onFetch = (id) => id == 'mai_anh'
          ? pending.future
          : Future.value(publicProfileFixture(id));
      final router = await open(tester, '/users/mai_anh', settle: false);
      await tester.pump();
      router.go('/users/bep_xinh');
      await tester.pumpAndSettle();
      pending.complete(publicProfileFixture('mai_anh'));
      await tester.pumpAndSettle();
      expect(find.text('Bếp Xinh'), findsOneWidget);
      expect(find.text('Mai Anh'), findsNothing);
      expect(profiles.requests, containsAllInOrder(['mai_anh', 'bep_xinh']));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'an empty public recipe list remains read-only and encoded ids are passed intact',
    (tester) async {
      const id = 'chef / a';
      profiles.onFetch = (requested) async => PublicProfileData(
        user: const PublicProfileUser(
          identity: RecipeAuthor(
            id: id,
            name: 'Bếp nhỏ',
            handle: 'bepnho',
            avatarAsset: 'assets/images/missing-avatar.png',
          ),
        ),
        recipes: [],
      );
      await open(tester, PathRouter.publicProfile(id));
      expect(profiles.requests, [id]);
      expect(find.text('Công thức đã chia sẻ (0)'), findsOneWidget);
      expect(find.text('Chưa có công thức được chia sẻ.'), findsOneWidget);
      expect(find.text('Sửa hồ sơ'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('legacy author names are shown without guessing a profile link', (
    tester,
  ) async {
    final original = detailFixture();
    details.onFetch = (id) async => RecipeDetailData(
      recipe: RecipeDetail(
        id: id,
        author: const RecipeAuthor.legacy(name: 'Tác giả cũ'),
        content: original.content,
      ),
      isFavorite: false,
      availableIngredientIds: {},
    );
    await open(tester, '/recipe/bo_ne_tieu_den');
    expect(find.text('Tác giả cũ'), findsOneWidget);
    expect(find.text('Xem hồ sơ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 800.0, 1024.0, 1280.0]) {
    testWidgets(
      'public profile supports large text and scrolling at width $width',
      (tester) async {
        await open(tester, '/users/linh_nguyen', width: width, scale: 1.5);
        expect(find.text('Linh Nguyễn'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byTooltip('Bò xào cà chua'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byTooltip('Bò xào cà chua'), findsOneWidget);
        expect(find.text('Sửa hồ sơ'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
