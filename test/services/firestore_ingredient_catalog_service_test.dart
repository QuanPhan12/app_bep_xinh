import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/ingredients/services/firestore_ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mock_services.dart';

import 'package:app_bep_xinh/features/ingredients/services/ingredient_discovery_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/models/recipe_draft.dart';

Map<String, dynamic> publishedCatalog() =>
    jsonDecode(File('data/catalogs/ingredients.v1.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('AI additions refresh independently of base TTL and retain recipe compatibility', () async {
    var reads = 0;
    var rows = <Map<String, dynamic>>[];
    final service = FirestoreIngredientCatalogService.withReader(
      readDocument: () async {
        reads++;
        return publishedCatalog();
      },
      readAdditions: () async => rows,
    );
    final base = await service.fetchCatalog();
    const name = 'Nấm tuyết xanh';
    final id = discoveredIngredientId(name);
    expect(id, discoveredIngredientId(' NAM   TUYET XANH '));
    Map<String, dynamic> row(String name) => {
      'id': discoveredIngredientId(name),
      'name': name,
      'nameKey': ingredientNameKey(name),
    };
    rows = [
      row(name),
      row('Thịt lợn'),
      {...row('Sai ID'), 'id': 'ai_bad'},
    ];
    final merged = await service.fetchCatalog();
    expect(reads, 1);
    expect(merged.ingredients.length, 232);
    expect((await service.search('nam tuyet')).single.id, id);
    expect(merged.byId[id]!.preferredUnitId, 'g');
    final json = RecipeIngredientDraft(
      id: 'new',
      ingredientId: id,
      name: name,
      amount: 100,
      unit: merged.unitsById['g'],
    ).toJson();
    expect(json['ingredientId'], isNull);
    json['id'] = 'new';
    // Admin/client cũ vẫn đọc như custom; client mới khôi phục cùng ID với Tủ lạnh.
    expect(RecipeIngredient.fromJson(json, base).ingredientId, isNull);
    final ingredient = RecipeIngredient.fromJson(json, merged);
    expect(ingredient.ingredientId, id);
    expect(ingredient.toJson()['ingredientId'], isNull);
  });
  test('published catalog has categories, compatible identities, defaults and immutable lists', () {
    final catalog = IngredientCatalog.fromJson(publishedCatalog());
    expect(catalog.ingredients.length, 231);
    expect(catalog.categories.length, 15);
    expect(catalog.units.length, 18);
    expect(catalog.version, '2026-11-09.v1');
    for (final old in catalogFixture().ingredients) {
      final item = catalog.byId[old.id]!;
      expect(item.unitIds, containsAll(old.unitIds));
      expect(item.unitIds, contains(item.preferredUnitId));
      expect(item.group, catalog.categoriesById[item.categoryId]!.name);
    }
    expect(catalog.byId['potato']!.preferredUnitId, 'bulb');
    expect(catalog.byId['tofu']!.matches('dau phu'), true);
    expect(catalog.byId['pork']!.matches('thit lon'), true);
    expect(catalog.byId['pineapple']!.matches('khom'), true);
    expect(() => catalog.categories.clear(), throwsUnsupportedError);
    expect(() => catalog.byId['tofu']!.unitIds.clear(), throwsUnsupportedError);
  });

  test('service coalesces reads, caches searches, refreshes after TTL and retains shared identity in fridge', () async {
    var reads = 0;
    var now = DateTime.utc(2026, 11, 9);
    final pending = Completer<Map<String, dynamic>?>();
    final service = FirestoreIngredientCatalogService.withReader(
      readDocument: () {
        reads++;
        return reads == 1 ? pending.future : Future.value(publishedCatalog());
      },
      now: () => now,
    );
    final first = service.fetchCatalog();
    expect(identical(first, service.fetchCatalog()), true);
    pending.complete(publishedCatalog());
    final catalog = await first;
    expect(identical(catalog, await service.fetchCatalog()), true);
    expect(
      (await service.search('ThỊt LợN')).map((item) => item.id),
      contains('pork'),
    );
    expect(reads, 1);
    final fridge = MockFridgeService(fixtureApi(), service);
    addTearDown(fridge.dispose);
    expect(
      identical(
        (await fridge.fetchFridge()).ingredientsById['egg'],
        catalog.byId['egg'],
      ),
      true,
    );
    now = now.add(const Duration(minutes: 16));
    expect(identical(catalog, await service.fetchCatalog()), false);
    expect(reads, 2);
  });

  test('failed reads, missing document and incompatible schema can be retried without mock fallback', () async {
    var reads = 0;
    final service = FirestoreIngredientCatalogService.withReader(
      readDocument: () async {
        reads++;
        if (reads == 1) throw StateError('offline');
        if (reads == 2) return null;
        if (reads == 3) return {...publishedCatalog(), 'schemaVersion': 2};
        return publishedCatalog();
      },
    );
    await expectLater(service.fetchCatalog(), throwsStateError);
    await expectLater(service.fetchCatalog(), throwsFormatException);
    await expectLater(service.fetchCatalog(), throwsFormatException);
    expect((await service.fetchCatalog()).ingredients.length, 231);
  });

  test('schema rejects dangling categories, units, defaults, duplicate IDs and unsupported locale', () {
    for (var index = 0; index < 6; index++) {
      final json = publishedCatalog();
      final item = (json['ingredients'] as List).first as Map<String, dynamic>;
      switch (index) {
        case 0:
          item['categoryId'] = 'unknown';
        case 1:
          item['unitIds'] = ['unknown'];
        case 2:
          item['defaultUnitId'] = 'unknown';
        case 3:
          (json['categories'] as List).add((json['categories'] as List).first);
        case 4:
          json['locale'] = 'en-US';
        case 5:
          (json['ingredients'] as List).add(item);
      }
      expect(
        () => IngredientCatalog.fromJson(json),
        throwsFormatException,
        reason: 'malformed case $index',
      );
    }
  });
}
