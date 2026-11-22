import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/ingredients/services/firestore_ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mock_services.dart';

Map<String, dynamic> publishedCatalog() =>
    jsonDecode(File('data/catalogs/ingredients.v1.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
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
