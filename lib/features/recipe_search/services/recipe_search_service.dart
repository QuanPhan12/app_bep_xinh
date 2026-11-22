import '../../recipes/services/published_recipe_source.dart';

import 'dart:async';

import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/core/utils/search_utils.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_content.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../models/recipe_search_request.dart';

abstract interface class RecipeSearchService {
  Future<List<RecipeItem>> search(RecipeSearchRequest request);
}

/// Published recipes only; pending editor submissions are not discoverable.
class MockRecipeSearchService implements RecipeSearchService {
  final MockApiClient api;
  final IngredientCatalogService catalogService;
  final RecipeFavoritesService favorites;
  final PublishedRecipeSource? published;
  MockRecipeSearchService(
    this.api,
    this.catalogService,
    this.favorites, {
    this.published,
  });

  @override
  Future<List<RecipeItem>> search(RecipeSearchRequest request) async {
    final (catalog, json) = await (
      catalogService.fetchCatalog(),
      api.get('recipe_details'),
    ).wait;
    final records = [
      ...await published?.fetchPublished() ?? <Map<String, dynamic>>[],
      ...JsonReader(json).objects('recipes'),
    ];
    requireUniqueIds(
      records.map((item) => JsonReader(item).string('id')),
      'recipes',
    );
    final terms = searchKey(request.query)
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty);
    final matches = <({Map<String, dynamic> json, DateTime? date})>[];
    for (final record in records) {
      final content = RecipeContent.fromJson(record, catalog);
      final category = request.filter.category;
      if (category != null && !content.categories.contains(category)) continue;
      final text = searchKey(
        [
          content.title,
          content.description,
          for (final ingredient in content.ingredients) ...[
            ingredient.name,
            ...?catalog.byId[ingredient.ingredientId]?.aliases,
          ],
        ].join(' '),
      );
      if (!terms.every(text.contains)) continue;
      final timestamp = JsonReader(record).optionalString('publishedAt');
      final date = timestamp == null ? null : DateTime.parse(timestamp).toUtc();
      matches.add((json: record, date: date));
    }
    if (request.filter == RecipeSearchFilter.newest) {
      matches.sort((a, b) {
        if (a.date != b.date) {
          if (a.date == null) return 1;
          if (b.date == null) return -1;
          return b.date!.compareTo(a.date!);
        }
        return (a.json['id'] as String).compareTo(b.json['id'] as String);
      });
    }
    return Future.wait(
      matches.map((record) async {
        final reader = JsonReader(record.json);
        final favorite = await favorites.isFavorite(
          reader.string('id'),
          fallback: reader.boolean('isFavorite'),
        );
        return RecipeItem.fromRecipeJson(record.json, isFavorite: favorite);
      }),
    );
  }
}
