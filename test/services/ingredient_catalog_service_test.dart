import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/models/recipe_draft.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_editor_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mock_services.dart';
import '../support/recipe_editor_fakes.dart';

class CountingApi extends MockApiClient {
  int requests = 0;
  bool failNext = false;
  CountingApi() : super(bundle: FixtureAssetBundle(), latency: Duration.zero);
  @override
  Future<Map<String, dynamic>> get(String resource) {
    requests++;
    if (failNext) {
      failNext = false;
      return Future.error(StateError('offline'));
    }
    return super.get(resource);
  }
}

void main() {
  test('catalog retries failed loads, deduplicates reads and shares identities with Fridge', () async {
    final api = CountingApi()..failNext = true;
    final service = MockIngredientCatalogService(api);
    await expectLater(service.fetchCatalog(), throwsStateError);
    final one = service.fetchCatalog();
    expect(identical(one, service.fetchCatalog()), isTrue);
    final catalog = await one;
    expect(identical(catalog, await service.fetchCatalog()), isTrue);
    expect(api.requests, 2);
    final fridge = MockFridgeService(fixtureApi(), service);
    addTearDown(fridge.dispose);
    final data = await fridge.fetchFridge();
    expect(identical(data.ingredientsById['egg'], catalog.byId['egg']), isTrue);
    expect((await service.search('dau phu')).single.id, 'tofu');
    expect((await service.search('thit lon')).single.id, 'pork');
    expect((await service.search(' TRUNG ')).single.id, 'egg');
    expect(() => catalog.unitsById.clear(), throwsUnsupportedError);
    expect(
      () => catalog.ingredients.first.aliases.clear(),
      throwsUnsupportedError,
    );
  });

  test('catalog rejects unknown units and submit rejects incompatible IDs or units', () async {
    final malformed = fixtureJson('ingredients');
    (malformed['ingredients'] as List).first['unitIds'] = ['unknown'];
    expect(() => IngredientCatalog.fromJson(malformed), throwsFormatException);
    final service = MockRecipeEditorService(
      fixtureApi(),
      MockIngredientCatalogService(fixtureApi()),
    );
    for (final item in [
      const RecipeIngredientDraft(
        id: 'row',
        ingredientId: 'unknown',
        name: 'Khác',
        toTaste: true,
      ),
      const RecipeIngredientDraft(
        id: 'row',
        ingredientId: 'egg',
        name: 'Trứng gà',
        amount: 2,
        unit: IngredientUnit(id: 'ml', label: 'ml'),
      ),
      const RecipeIngredientDraft(
        id: 'row',
        name: 'Khác',
        amount: 2,
        unit: IngredientUnit(id: 'unknown', label: 'khác'),
      ),
    ]) {
      await expectLater(
        service.submit(validRecipeDraft().copyWith(ingredients: [item])),
        throwsFormatException,
      );
    }
    await service.submit(validRecipeDraft());
  });
}
