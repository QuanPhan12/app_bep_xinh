import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:app_bep_xinh/features/fridge/models/fridge_summary.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';

import '../models/home_data.dart';

abstract interface class HomeService {
  Stream<FridgeSummary> get fridgeSummaries;
  Stream<RecipeFavoriteChange> get favoriteChanges;
  Future<HomeData> fetchHome();
  Future<void> setFavorite(String recipeId, bool isFavorite);
}

class MockHomeService implements HomeService {
  final MockApiClient api;
  final FridgeService fridgeService;
  final RecipeFavoritesService favorites;

  MockHomeService(this.api, this.fridgeService, this.favorites);

  @override
  Stream<FridgeSummary> get fridgeSummaries => fridgeService.summaries;

  @override
  Future<HomeData> fetchHome() async {
    final (json, fridge) = await (
      api.get('home'),
      fridgeService.fetchFridge(),
    ).wait;
    final data = HomeData.fromJson(json, FridgeSummary.fromData(fridge));
    final recipes = await Future.wait(
      data.recipes.map(
        (recipe) async => recipe.copyWith(
          isFavorite: await favorites.isFavorite(
            recipe.id,
            fallback: recipe.isFavorite,
          ),
        ),
      ),
    );
    return data.withRecipes(recipes);
  }

  @override
  Stream<RecipeFavoriteChange> get favoriteChanges => favorites.changes;

  @override
  Future<void> setFavorite(String recipeId, bool isFavorite) =>
      favorites.setFavorite(recipeId, isFavorite);
}
