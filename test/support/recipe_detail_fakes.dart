import 'dart:async';

import 'package:app_bep_xinh/features/recipe_detail/models/recipe_detail.dart';
import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import 'mock_services.dart';

RecipeDetail detailFixture([String id = 'bo_ne_tieu_den']) =>
    RecipeDetail.fromJson(
      (fixtureJson('recipe_details')['recipes'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((item) => item['id'] == id),
      catalogFixture(),
    );
RecipeDetailData detailDataFixture([String id = 'bo_ne_tieu_den']) =>
    RecipeDetailData(
      recipe: detailFixture(id),
      isFavorite: false,
      availableIngredientIds: {'egg'},
    );

class StubRecipeDetailService implements RecipeDetailService {
  int calls = 0;
  Future<RecipeDetailData> Function(String)? onFetch;
  @override
  Future<RecipeDetailData> fetchRecipe(String id) {
    calls++;
    return onFetch?.call(id) ?? Future.value(detailDataFixture(id));
  }
}

class StubRecipeFavoritesService implements RecipeFavoritesService {
  final controller = StreamController<RecipeFavoriteChange>.broadcast();
  final values = <String, bool>{};
  Future<void> Function(String, bool)? onSet;
  int writes = 0;
  @override
  Stream<RecipeFavoriteChange> get changes => controller.stream;
  @override
  Future<bool> isFavorite(String id, {required bool fallback}) async =>
      values[id] ?? fallback;
  @override
  Future<void> setFavorite(String id, bool value) async {
    writes++;
    await onSet?.call(id, value);
    values[id] = value;
    controller.add(RecipeFavoriteChange(id, value));
  }

  @override
  Future<void> dispose() => controller.close();
}
