import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_bep_xinh/features/offline_recipes/services/offline_recipe_service.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/core/tap/app_tap_handler.dart';
import 'package:app_bep_xinh/features/kitchen/models/kitchen_entry.dart';
import 'package:app_bep_xinh/features/kitchen/services/kitchen_services.dart';
import 'package:app_bep_xinh/features/kitchen/cubits/kitchen_list_cubit.dart';
import 'package:app_bep_xinh/features/kitchen/screens/kitchen_hub_screen.dart';
import 'package:app_bep_xinh/features/cooking_timers/services/cooking_timer_service.dart';
import 'package:app_bep_xinh/features/cooking_timers/screens/cooking_timers_screen.dart';
import 'package:app_bep_xinh/features/offline_recipes/screens/offline_recipes_screen.dart';
import 'package:app_bep_xinh/features/meal_planner/cubits/meal_planner_cubit.dart';
import 'package:app_bep_xinh/features/meal_planner/screens/meal_planner_screen.dart';
import 'package:app_bep_xinh/features/pantry/cubits/pantry_cubit.dart';
import 'package:app_bep_xinh/features/pantry/screens/pantry_screen.dart';
import 'package:app_bep_xinh/features/recipe_collections/screens/recipe_collections_screen.dart';
import 'package:app_bep_xinh/features/cooking_journal/screens/cooking_journal_screen.dart';
import 'package:app_bep_xinh/features/following/screens/following_screen.dart';
import 'package:app_bep_xinh/features/recipe_reviews/screens/recipe_reviews_screen.dart';
import 'package:app_bep_xinh/features/recipe_detail/models/recipe_detail.dart';

import '../support/kitchen_fakes.dart';
import '../support/mock_services.dart';
import '../support/test_text_styles.dart';

void main() {
  setUpAll(configureTestTextStyles);
  test(
    'offline rejects duplicate ingredient references consistently with domain',
    () {
      final json =
          (fixtureJson('recipe_details')['recipes'] as List).first
              as Map<String, dynamic>;
      final recipe = RecipeDetail.fromJson(json, catalogFixture());
      final saved = OfflineRecipe(recipe, DateTime.utc(2026)).toJson();
      final content = saved['recipe'] as Map<String, dynamic>;
      final base =
          (content['ingredients'] as List).first as Map<String, dynamic>;
      content['ingredients'] = [
        {
          ...base,
          'id': 'a',
          'ingredientId': 'egg',
          'name': 'Egg',
          'amount': 2,
          'unitId': 'fruit',
          'toTaste': false,
        },
        {
          ...base,
          'id': 'b',
          'ingredientId': 'egg',
          'name': 'Egg',
          'amount': 100,
          'unitId': 'g',
          'toTaste': false,
        },
        {
          ...base,
          'id': 'c',
          'ingredientId': 'egg',
          'name': 'Egg',
          'amount': null,
          'unitId': null,
          'toTaste': true,
        },
      ];
      saved['units'] = {
        'fruit': {'id': 'fruit', 'label': 'quả', 'type': 'count'},
        'g': {'id': 'g', 'label': 'g', 'type': 'mass'},
      };
      expect(() => OfflineRecipe.fromJson(saved), throwsFormatException);
    },
  );
  test(
    'offline remote failure or withdrawal keeps previous version atomically',
    () async {
      final storage = MemoryKitchenStorage();
      var status = 200, requests = 0, publishedChecks = 0;
      var withdraw = false;
      final service = OfflineRecipeService(
        storage: storage,
        storageKey: 'a',
        checkSession: () {},
        isPublished: (_) async => !withdraw || ++publishedChecks < 2,
        client: MockClient((request) async {
          requests++;
          expect(request.url.path, contains('w_720,q_65,f_jpg'));
          return http.Response.bytes([1, 2, 3], status);
        }),
      );
      final json =
          (fixtureJson('recipe_details')['recipes'] as List).first
              as Map<String, dynamic>;
      final recipe = RecipeDetail.fromJson({
        ...json,
        'cover': const RecipeImage.remote(
          id: 'photo',
          name: 'Photo',
          url: 'https://res.cloudinary.com/ddqouziau/image/upload/v1/test.jpg',
          publicId: 'test',
        ).toJson(),
      }, catalogFixture());
      await service.download(recipe);
      expect((await service.list()).single.recipe.cover!.bytes, [1, 2, 3]);
      expect(requests, 1);
      status = 404;
      await expectLater(service.download(recipe), throwsStateError);
      expect((await service.list()).length, 1);
      status = 200;
      withdraw = true;
      await expectLater(service.download(recipe), throwsStateError);
      expect((await service.list()).length, 1);
    },
  );
  test('strict calendar, collections and pantry quantities round trip', () {
    expect(() => kitchenDate('2026-02-30'), throwsFormatException);
    expect(dateKey(kitchenDate('2028-02-29')), '2028-02-29');
    final collection = RecipeCollection(
      id: 'a',
      name: 'Weekend',
      recipeIds: ['r_1', 'r_2'],
    );
    expect(RecipeCollection.fromJson('a', collection.toJson()).recipeIds, [
      'r_1',
      'r_2',
    ]);
    expect(
      () => RecipeCollection(
        id: 'a',
        name: 'a',
        recipeIds: ['r_1', 'r_1'],
      ).toJson(),
      throwsFormatException,
    );
    expect(
      () => const PantryLot(
        id: 'a',
        ingredientId: 'egg',
        name: 'Egg',
        amount: double.nan,
        unitId: 'fruit',
      ).toJson(),
      throwsFormatException,
    );
    expect(
      () => const PantryLot(
        id: 'a',
        ingredientId: 'egg',
        name: 'Egg',
        amount: 1,
      ).toJson(),
      throwsFormatException,
    );
    const lot = PantryLot(
      id: 'a',
      ingredientId: 'egg',
      name: 'Egg',
      expiresOn: '2026-11-17',
    );
    expect(lot.isSoon(DateTime(2026, 11, 16)), true);
    expect(lot.isExpired(DateTime(2026, 11, 18)), true);
  });
  test(
    'timers persist absolute deadlines, pause and recover after restart',
    () async {
      final storage = MemoryKitchenStorage();
      var now = DateTime.utc(2026, 11, 16, 10);
      var active = true;
      CookingTimerService create() => CookingTimerService(
        storage: storage,
        storageKey: 'a',
        checkSession: () {
          if (!active) throw StateError('session changed');
        },
        now: () => now,
      );
      var service = create();
      await service.start('Boil', const Duration(minutes: 10));
      now = now.add(const Duration(minutes: 3));
      expect(service.items.single.remaining(now), const Duration(minutes: 7));
      await service.toggle(service.items.single.id);
      now = now.add(const Duration(hours: 1));
      expect(service.items.single.remaining(now), const Duration(minutes: 7));
      service.dispose();
      service = create();
      await service.load();
      expect(service.items.single.paused, true);
      await service.toggle(service.items.single.id);
      now = now.add(const Duration(minutes: 8));
      expect(service.items.single.remaining(now), Duration.zero);
      storage.fail = true;
      await expectLater(
        service.remove(service.items.single.id),
        throwsStateError,
      );
      expect(service.items.length, 1);
      active = false;
      await expectLater(
        service.start('x', const Duration(seconds: 2)),
        throwsStateError,
      );
      service.dispose();
    },
  );
  test('timer count and duration bounds survive failed commands', () async {
    final service = CookingTimerService(
      storage: MemoryKitchenStorage(),
      storageKey: 'a',
      checkSession: () {},
    );
    addTearDown(service.dispose);
    await expectLater(service.start('x', Duration.zero), throwsFormatException);
    await expectLater(
      service.start('x', const Duration(hours: 24)),
      throwsFormatException,
    );
    for (var i = 0; i < 8; i++) {
      await service.start('$i', const Duration(minutes: 1));
    }
    await expectLater(
      service.start('ninth', const Duration(seconds: 1)),
      throwsFormatException,
    );
    expect(service.items.length, 8);
    await service.remove(service.items.first.id);
    await service.start('replacement', const Duration(seconds: 1));
    expect(service.items.length, 8);
  });
  test('offline saves full local images, survives reload, rejects capacity overflow', () async {
    final services = kitchenFixture();
    addTearDown(() => disposeKitchen(services));
    final json =
        (fixtureJson('recipe_details')['recipes'] as List).first
            as Map<String, dynamic>;
    final recipe = RecipeDetail.fromJson({
      ...json,
      'cover': RecipeImage.memory(
        id: 'small',
        name: 'small',
        bytes: Uint8List.fromList([1, 2, 3]),
      ).toJson(),
      'steps': (json['steps'] as List)
          .map((step) => {...step as Map<String, dynamic>, 'photo': null})
          .toList(),
    }, catalogFixture());
    await services.offline.download(recipe);
    var saved = (await services.offline.list()).single;
    expect(saved.recipe.steps.length, recipe.steps.length);
    expect(saved.recipe.ingredients.length, recipe.ingredients.length);
    expect(saved.recipe.cover!.bytes, isNotEmpty);
    expect(saved.recipe.cover!.assetPath, isNull);
    await services.offline.download(recipe);
    expect((await services.offline.list()).length, 1);
    final large = RecipeDetail(
      id: 'large',
      author: recipe.author,
      content: RecipeContent.fromJson({
        ...recipe.content.toJson(),
        'cover': RecipeImage.memory(
          id: 'large',
          name: 'large',
          bytes: Uint8List(790000),
        ).toJson(),
      }, catalogFixture()),
    );
    await services.offline.download(large);
    final third = RecipeDetail(
      id: 'third',
      author: recipe.author,
      content: large.content,
    );
    await expectLater(services.offline.download(third), throwsFormatException);
    expect((await services.offline.list()).length, 2);
    await services.offline.remove(recipe.id);
    expect((await services.offline.list()).single.recipe.id, 'large');
  });
  test(
    'pantry uses current stored quantity and never consumes below zero',
    () async {
      final services = kitchenFixture();
      addTearDown(() => disposeKitchen(services));
      final cubit = PantryCubit(services);
      addTearDown(cubit.close);
      await services.pantry.save(
        const PantryLot(
          id: 'lot',
          ingredientId: 'egg',
          name: 'Egg',
          amount: 3,
          unitId: 'fruit',
        ),
      );
      expect(await cubit.consume('lot', 2), true);
      expect(await cubit.consume('lot', 2), false);
      expect((await services.pantry.fetch()).single.amount, 1);
    },
  );
  test(
    'planner copy retry and cooking session overwrite do not duplicate',
    () async {
      final services = kitchenFixture();
      addTearDown(() => disposeKitchen(services));
      final cubit = MealPlannerCubit(services);
      addTearDown(cubit.close);
      const ref = RecipeRef(id: 'r_1', title: 'Meal', authorId: 'bob');
      await services.meals.save(
        const MealPlanEntry(
          id: 'meal',
          day: '2026-11-16',
          slot: MealSlot.lunch,
          recipe: ref,
          servings: 2,
        ),
      );
      cubit.load();
      await Future<void>.delayed(Duration.zero);
      expect(await cubit.copyDay('2026-11-16', '2026-11-17'), true);
      expect(await cubit.copyDay('2026-11-16', '2026-11-17'), true);
      expect(await services.meals.count(), 2);
      for (var i = 0; i < 2; i++) {
        await services.journal.save(
          CookingLog(
            id: 'session',
            recipe: ref,
            day: '2026-11-16',
            servings: 2,
            note: '$i',
          ),
        );
      }
      expect(await services.journal.count(), 1);
      expect((await services.journal.fetch()).single.note, '1');
    },
  );
  test('failed write keeps list and permits retry', () async {
    final repository = MemoryKitchenRepository<RecipeCollection>();
    addTearDown(repository.dispose);
    final cubit = KitchenListCubit(repository);
    addTearDown(cubit.close);
    cubit.load();
    await Future<void>.delayed(Duration.zero);
    repository.fail = true;
    expect(
      await cubit.save(RecipeCollection(id: 'a', name: 'A', recipeIds: [])),
      false,
    );
    expect(cubit.state.error, isNotNull);
    repository.fail = false;
    expect(
      await cubit.save(RecipeCollection(id: 'a', name: 'A', recipeIds: [])),
      true,
    );
    expect(await repository.count(), 1);
  });
  for (final dark in [false, true]) {
    for (final size in [
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1024, 768),
    ]) {
      testWidgets('new screens fit $size dark=$dark at large text', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final services = kitchenFixture();
        final raw =
            (fixtureJson('recipe_details')['recipes'] as List).first
                as Map<String, dynamic>;
        final recipe = RecipeDetail.fromJson({
          ...raw,
          'cover': const RecipeImage.asset(
            id: 'small',
            name: 'small',
            assetPath: 'assets/images/logo.png',
          ).toJson(),
        }, catalogFixture());
        final ref = RecipeRef.fromRecipe(recipe);
        final day = dateKey(DateTime.now());
        await services.meals.save(
          MealPlanEntry(
            id: 'meal',
            day: day,
            slot: MealSlot.lunch,
            recipe: ref,
            servings: 2,
          ),
        );
        await services.collections.save(
          RecipeCollection(
            id: 'group',
            name: 'Bữa cơm gia đình cuối tuần',
            recipeIds: [recipe.id],
          ),
        );
        await services.pantry.save(
          const PantryLot(
            id: 'lot',
            ingredientId: 'egg',
            name: 'Trứng gà và nguyên liệu để nấu bữa cơm',
            amount: 3,
            unitId: 'fruit',
            expiresOn: '2026-11-16',
          ),
        );
        await services.journal.save(
          CookingLog(
            id: 'session',
            recipe: ref,
            day: day,
            servings: 2,
            note: 'Lần sau giảm lửa và nêm gia vị sau cùng.',
          ),
        );
        await services.following.save(
          const FollowedAuthor(
            id: 'bob',
            name: 'Người yêu bếp và các món ăn gia đình',
          ),
        );
        await services.timers.start(
          'Nấu món ăn cho cả gia đình · Bước 2',
          const Duration(minutes: 5),
        );
        await tester.runAsync(() => services.offline.download(recipe));
        for (final screen in <Widget>[
          const KitchenHubScreen(),
          const MealPlannerScreen(),
          const PantryScreen(),
          const RecipeCollectionsScreen(),
          const RecipeCollectionDetailScreen(id: 'group'),
          const CookingJournalScreen(),
          const CookingTimersScreen(),
          const OfflineRecipesScreen(),
          OfflineRecipeScreen(id: recipe.id),
          const FollowingScreen(),
          const FollowingFeedScreen(),
          const RecipeReviewsScreen(recipeId: 'r_a'),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              home: KitchenScope(
                services: services,
                child: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: const TextScaler.linear(2),
                  ),
                  child: screen,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: screen.runtimeType.toString(),
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        }
        await disposeKitchen(services);
      });
    }
  }
  testWidgets(
    'collection dialog retains input after failure with tablet keyboard',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1024, 768);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final services = kitchenFixture();
      addTearDown(() => disposeKitchen(services));
      final repository =
          services.collections as MemoryKitchenRepository<RecipeCollection>;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: KitchenScope(
            services: services,
            child: const RecipeCollectionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo bộ sưu tập'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Món cuối tuần');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      repository.fail = true;
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Món cuối tuần'), findsOneWidget);
      expect(tester.takeException(), isNull);
      repository.fail = false;
      AppTapHandler.resetLock();
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      expect(await repository.count(), 1);
      expect(find.text('Món cuối tuần'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
