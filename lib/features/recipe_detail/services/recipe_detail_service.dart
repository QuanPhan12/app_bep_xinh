import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../models/recipe_detail.dart';

class RecipeNotFoundException implements Exception {
  const RecipeNotFoundException();
}

abstract interface class RecipeDetailService {
  Future<RecipeDetailData> fetchRecipe(String id);
}

class MockRecipeDetailService implements RecipeDetailService {
  final MockApiClient api;
  final IngredientCatalogService catalogService;
  final FridgeService fridgeService;
  final RecipeFavoritesService favorites;
  MockRecipeDetailService(
    this.api,
    this.catalogService,
    this.fridgeService,
    this.favorites,
  );

  @override
  Future<RecipeDetailData> fetchRecipe(String id) async {
    final (json, catalog, fridge) = await (
      api.get('recipe_details'),
      catalogService.fetchCatalog(),
      fridgeService.fetchFridge(),
    ).wait;
    final entries = JsonReader(json).objects('recipes');
    final ids = <String>[];
    Map<String, dynamic>? matching;
    for (final entry in entries) {
      final reader = JsonReader(entry);
      final keys = [reader.string('id'), ...reader.strings('aliases')];
      ids.addAll(keys);
      if (keys.contains(id)) matching = entry;
    }
    requireUniqueIds(ids, 'recipe detail ids and aliases');
    if (matching == null) throw const RecipeNotFoundException();
    final recipe = RecipeDetail.fromJson(matching, catalog);
    return RecipeDetailData(
      recipe: recipe,
      isFavorite: await favorites.isFavorite(
        recipe.id,
        fallback: recipe.isFavorite,
      ),
      availableIngredientIds: fridge.selectedIds.toSet(),
    );
  }
}
