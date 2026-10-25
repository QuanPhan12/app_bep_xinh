import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/recipe_search/models/recipe_search_request.dart';
import 'package:app_bep_xinh/features/recipe_search/services/recipe_search_service.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_content.dart';

import '../support/mock_services.dart';
import '../support/recipe_detail_fakes.dart';

class SearchFixtureApi extends MockApiClient {
  final Map<String, dynamic> recipes;
  SearchFixtureApi(this.recipes);
  @override
  Future<Map<String, dynamic>> get(String resource) async =>
      resource == 'recipe_details' ? recipes : fixtureJson(resource);
}

void main() {
  late StubRecipeFavoritesService favorites;
  late MockRecipeSearchService service;
  setUp(() {
    favorites = StubRecipeFavoritesService();
    final api = fixtureApi();
    service = MockRecipeSearchService(
      api,
      MockIngredientCatalogService(api),
      favorites,
    );
  });
  tearDown(() => favorites.dispose());

  test(
    'search matches all tokens without accents, by title and catalog aliases',
    () async {
      final accented = await service.search(
        const RecipeSearchRequest(query: '  CÁ HỒI  '),
      );
      final unaccented = await service.search(
        const RecipeSearchRequest(query: 'ca   hoi'),
      );
      expect(accented.map((r) => r.id), ['ca_hoi_ap_chao']);
      expect(unaccented, accented);
      final catalog = catalogFixture();
      final ingredient = catalog.ingredients.firstWhere(
        (i) =>
            i.aliases.isNotEmpty &&
            (fixtureJson('recipe_details')['recipes'] as List).any(
              (r) => (r['ingredients'] as List).any(
                (item) => item['ingredientId'] == i.id,
              ),
            ),
      );
      final aliasResults = await service.search(
        RecipeSearchRequest(query: ingredient.aliases.first),
      );
      final expected = (fixtureJson('recipe_details')['recipes'] as List)
          .where(
            (r) => (r['ingredients'] as List).any(
              (item) => item['ingredientId'] == ingredient.id,
            ),
          )
          .map((r) => r['id']);
      expect(aliasResults.map((r) => r.id), containsAll(expected));
      expect(
        await service.search(const RecipeSearchRequest(query: 'zzzzzzz')),
        isEmpty,
      );
    },
  );

  test(
    'four filters use authored classifications and intersect with query',
    () async {
      final records = (fixtureJson('recipe_details')['recipes'] as List)
          .cast<Map<String, dynamic>>();
      for (final filter in RecipeSearchFilter.values.where(
        (f) => f.category != null,
      )) {
        final results = await service.search(
          RecipeSearchRequest(filter: filter),
        );
        expect(results, isNotEmpty);
        expect(
          results.map((r) => r.id).toSet(),
          records
              .where(
                (r) => (r['categories'] as List).contains(filter.category!.id),
              )
              .map((r) => r['id'])
              .toSet(),
        );
      }
      expect(
        await service.search(
          const RecipeSearchRequest(
            query: 'ca hoi',
            filter: RecipeSearchFilter.vegetarian,
          ),
        ),
        isEmpty,
      );
      final all = await service.search(const RecipeSearchRequest());
      expect(all, hasLength(records.length));
      expect(all.first.cookTimeMinutes, 30);
    },
  );

  test(
    'newest sorts server dates and favorites share the same source',
    () async {
      final newest = await service.search(
        const RecipeSearchRequest(filter: RecipeSearchFilter.newest),
      );
      final records = (fixtureJson('recipe_details')['recipes'] as List)
          .cast<Map<String, dynamic>>();
      records.sort(
        (a, b) =>
            DateTime.parse(b['publishedAt'])
                .compareTo(DateTime.parse(a['publishedAt'])),
      );
      expect(newest.map((r) => r.id), records.map((r) => r['id']));
      await favorites.setFavorite(newest.first.id, true);
      expect(
        (await service.search(
          const RecipeSearchRequest(filter: RecipeSearchFilter.newest),
        )).first.isFavorite,
        isTrue,
      );
    },
  );

  test('classification survives authored content and unknown/system tags are rejected', () async {
    final json = fixtureJson('recipe_details');
    final record = (json['recipes'] as List).first as Map<String, dynamic>;
    record['categories'] = ['vegetarian'];
    final custom = MockRecipeSearchService(
      SearchFixtureApi(json),
      MockIngredientCatalogService(fixtureApi()),
      favorites,
    );
    final results = await custom.search(
      const RecipeSearchRequest(filter: RecipeSearchFilter.vegetarian),
    );
    expect(results.map((r) => r.id), contains(record['id']));
    final content = RecipeContent.fromJson(record, catalogFixture());
    expect(
      RecipeContent.fromJson(content.toJson(), catalogFixture()).categories,
      {RecipeCategory.vegetarian},
    );
    record['categories'] = ['new'];
    await expectLater(
      custom.search(const RecipeSearchRequest()),
      throwsFormatException,
    );
    record.remove('categories');
    expect(
      RecipeContent.fromJson(record, catalogFixture()).categories,
      isEmpty,
    );
  });
}
