import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';
import 'package:app_bep_xinh/features/recipe_detail/models/recipe_detail.dart';
import 'package:app_bep_xinh/features/recipe_detail/cubits/recipe_detail/recipe_detail_cubit.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:app_bep_xinh/features/home/cubits/home/home.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';

import '../support/mock_services.dart';

void main() {
  test('every Home/banner/Fridge recipe resolves to the correct detail and unknown ids fail', () async {
    final api = fixtureApi();
    final fridge = createMockFridgeService();
    final favorites = MockRecipeFavoritesService(api);
    addTearDown(fridge.dispose);
    addTearDown(favorites.dispose);
    final service = MockRecipeDetailService(
      api,
      MockIngredientCatalogService(api),
      fridge,
      favorites,
    );
    final ids = {
      ...homeFixture().recipes.map((e) => e.id),
      ...homeFixture().banners.map((e) => e.id),
      ...fridgeFixture().recipes.map((e) => e.id),
    };
    for (final id in ids) {
      final data = await service.fetchRecipe(id);
      expect(data.recipe.ingredients, isNotEmpty);
      expect(data.recipe.steps, isNotEmpty);
    }
    expect(
      (await service.fetchRecipe('salmon_garlic')).recipe.id,
      'ca_hoi_ap_chao',
    );
    await expectLater(
      service.fetchRecipe('missing'),
      throwsA(isA<RecipeNotFoundException>()),
    );
  });
  test('detail validates ingredient references, amount, servings and duplicate steps', () {
    final raw =
        (fixtureJson('recipe_details')['recipes'] as List).first
            as Map<String, dynamic>;
    for (final amount in [0, -1, double.infinity, double.nan]) {
      final copy = {
        ...raw,
        'ingredients': [
          {
            ...(raw['ingredients'] as List).first as Map<String, dynamic>,
            'amount': amount,
          },
        ],
      };
      expect(
        () => RecipeDetail.fromJson(copy, catalogFixture()),
        throwsFormatException,
      );
    }
    expect(
      () => RecipeDetail.fromJson({...raw, 'servings': 0}, catalogFixture()),
      throwsFormatException,
    );
    expect(
      () => RecipeDetail.fromJson({
        ...raw,
        'steps': [(raw['steps'] as List).first, (raw['steps'] as List).first],
      }, catalogFixture()),
      throwsFormatException,
    );
    final parsed = RecipeDetail.fromJson(raw, catalogFixture());
    expect(() => parsed.ingredients.clear(), throwsUnsupportedError);
    final tiny = RecipeDetailIngredient(
      id: 'tiny',
      name: 'Gia vị',
      amount: .0001,
      unit: catalogFixture().unitsById['kg'],
    );
    expect(tiny.quantity(1), '0,0001 kg');
    expect(tiny.quantity(2), '0,0002 kg');
    final fractional = RecipeDetailIngredient(
      id: 'fraction',
      name: 'Gia vị',
      amount: 1,
      unit: catalogFixture().unitsById['g'],
    );
    expect(fractional.quantity(1 / 3), '0,333 g');
  });
  test(
    'saving in detail updates an already loaded Home and survives re-opening',
    () async {
      final api = fixtureApi();
      final fridge = createMockFridgeService();
      final favorites = MockRecipeFavoritesService(api);
      final service = MockRecipeDetailService(
        api,
        MockIngredientCatalogService(api),
        fridge,
        favorites,
      );
      final home = HomeCubit(service: MockHomeService(api, fridge, favorites));
      final detail = RecipeDetailCubit(
        recipeId: 'bo_ne_tieu_den',
        service: service,
        favorites: favorites,
      );
      await Future.wait([home.loadHome(), detail.load()]);
      await detail.toggleFavorite();
      await Future<void>.value();
      expect(home.state.recipes.first.isFavorite, isTrue);
      expect((await service.fetchRecipe('bo_ne_tieu_den')).isFavorite, isTrue);
      await home.toggleFavorite('bo_ne_tieu_den');
      await Future<void>.value();
      expect(detail.state.isFavorite, isFalse);
      await detail.close();
      await home.close();
      await favorites.dispose();
      await fridge.dispose();
    },
  );
}
