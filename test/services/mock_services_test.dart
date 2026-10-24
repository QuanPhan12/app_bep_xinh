import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';
import 'package:app_bep_xinh/features/home/cubits/home/home.dart';
import 'package:app_bep_xinh/features/fridge/cubits/fridge/fridge_cubit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mock_services.dart';

class InvalidJsonBundle extends FixtureAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      'invalid json';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled fixtures are loadable through the real asset bundle', () async {
    final api = MockApiClient(bundle: rootBundle, latency: Duration.zero);
    final fridge = MockFridgeService(api, MockIngredientCatalogService(api));
    addTearDown(fridge.dispose);
    final home = await MockHomeService(
      api,
      fridge,
      MockRecipeFavoritesService(api),
    ).fetchHome();
    expect(home.banners.length, 3);
    expect(home.categories.length, 5);
    expect(home.recipes.length, 4);
    expect(home.fridgeSummary.readyRecipeCount, 2);
  });

  test(
    'writes survive refetch and Home summary follows shared fridge inventory',
    () async {
      final api = fixtureApi();
      final fridge = MockFridgeService(api, MockIngredientCatalogService(api));
      addTearDown(fridge.dispose);
      final home = MockHomeService(
        api,
        fridge,
        MockRecipeFavoritesService(api),
      );
      final before = await home.fetchHome();
      final recipeId = before.recipes.first.id;
      await home.setFavorite(recipeId, true);
      await fridge.saveInventory(['egg', 'tomato', 'scallion', 'beef']);
      final after = await home.fetchHome();
      expect(after.recipes.first.isFavorite, isTrue);
      expect(after.fridgeSummary.ingredientNames, contains('Thịt bò'));
      expect(after.fridgeSummary.ingredientNames, isNot(contains('Đậu hũ')));
      expect(after.fridgeSummary.readyRecipeCount, 2);
      expect((await fridge.fetchFridge()).selectedIds, [
        'egg',
        'tomato',
        'scallion',
        'beef',
      ]);
    },
  );

  test('invalid responses propagate to callers instead of silently using static data', () async {
    final service = MockFridgeService(
      MockApiClient(bundle: InvalidJsonBundle(), latency: Duration.zero),
      MockIngredientCatalogService(fixtureApi()),
    );
    addTearDown(service.dispose);
    await expectLater(service.fetchFridge(), throwsFormatException);
  });

  test(
    'inventory writes update loaded Home without fetching Home again',
    () async {
      final fridge = createMockFridgeService();
      final home = HomeCubit(
        service: MockHomeService(
          fixtureApi(),
          fridge,
          MockRecipeFavoritesService(fixtureApi()),
        ),
      );
      final inventory = FridgeCubit(service: fridge);
      await Future.wait([home.loadHome(), inventory.loadFridge()]);
      expect(home.state.data!.fridgeSummary.readyRecipeCount, 2);
      await inventory.clearIngredients();
      await Future<void>.value();
      expect(home.state.data!.fridgeSummary.readyRecipeCount, 0);
      expect(home.state.data!.fridgeSummary.ingredientNames, isEmpty);
      await home.close();
      await inventory.close();
      await fridge.dispose();
    },
  );

  test('invalid inventory write does not poison later writes', () async {
    final fridge = createMockFridgeService();
    addTearDown(fridge.dispose);
    await fridge.fetchFridge();
    await expectLater(fridge.saveInventory(['unknown']), throwsArgumentError);
    await fridge.saveInventory(['egg']);
    expect((await fridge.fetchFridge()).selectedIds, ['egg']);
  });
}
