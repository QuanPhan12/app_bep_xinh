import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_bep_xinh/core/services/firestore_user_store.dart';
import 'package:app_bep_xinh/features/ai_chat/services/firestore_direct_ai_store.dart';
import 'package:app_bep_xinh/features/kitchen/models/kitchen_entry.dart';
import 'package:app_bep_xinh/features/kitchen/services/kitchen_repository.dart';
import 'package:app_bep_xinh/features/nutrition/models/nutrition.dart';
import 'package:app_bep_xinh/features/nutrition/services/nutrition_ai_store.dart';
import 'package:app_bep_xinh/features/ingredients/services/firestore_ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/ingredients/services/firestore_ingredient_discovery_service.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_discovery_service.dart';

Future<void> nutritionSdkSmoke(FirestoreUserStore store) async {
  void check(bool v, String name) {
    if (!v) throw StateError(name);
  }

  const a = '11111111111111111111111111111111',
      b = '22222222222222222222222222222222',
      c = '33333333333333333333333333333333',
      d = '44444444444444444444444444444444';
  final jobs = FirestoreNutritionAiStore(store),
      chat = FirestoreDirectAiStore(store.firestore);
  final digest = 'a' * 64;
  final first = await jobs.reserve(a, digest, 3);
  var denied = false;
  try {
    await chat.reserve(store.uid, b, 'Chat cùng hạn mức', 3);
  } catch (_) {
    denied = true;
  }
  check(denied, 'nutrition lease blocks concurrent chat');
  await jobs.finish(a, first.lease, '{"items":[]}');
  final second = await chat.reserve(store.uid, b, 'Chat cùng hạn mức', 3);
  denied = false;
  try {
    await jobs.reserve(c, digest, 3);
  } catch (_) {
    denied = true;
  }
  check(denied, 'chat lease blocks concurrent nutrition');
  await chat.fail(store.uid, b, second.lease);
  final third = await jobs.reserve(c, digest, 3);
  await jobs.finish(c, third.lease, '{"items":[]}');
  denied = false;
  try {
    await jobs.reserve(d, digest, 3);
  } catch (_) {
    denied = true;
  }
  check(denied, 'chat and nutrition share daily quota');
  check(
    (await jobs.reserve(a, digest, 3)).result == '{"items":[]}',
    'nutrition retries use cached result even at limit',
  );
  final day = DateTime.now()
      .toUtc()
      .add(const Duration(hours: 7))
      .toIso8601String()
      .substring(0, 10);
  final quota =
      (await store.firestore
              .doc('ai_chat_threads/${store.uid}/days/$day')
              .get())
          .data()!;
  check(
    quota['count'] == 3 && quota['activeUntil'] == 0,
    'shared quota transaction final state',
  );
  final history = await chat.recentHistory(store.uid);
  check(history.isEmpty, 'nutrition does not enter chat history');
  final catalog = FirestoreIngredientCatalogService(store.firestore);
  final discoveries = FirestoreIngredientDiscoveryService(store, catalog);
  const newName = 'Nấm tuyết xanh SDK';
  await Future.wait([
    discoveries.saveDiscovered(a, [newName, 'Thịt lợn', 'NAM TUYET XANH SDK']),
    discoveries.saveDiscovered(c, [newName]),
  ]);
  final refreshed = await catalog.fetchCatalog();
  final addition = refreshed.byId[discoveredIngredientId(newName)];
  check(
    addition != null && addition.preferredUnitId == 'g',
    'AI ingredient added to shared catalog',
  );
  check(
    refreshed.ingredients.length == 232,
    'concurrent discoveries deduplicate names and existing aliases',
  );
  check(
    (await catalog.search('nam tuyet xanh sdk')).single.id == addition!.id,
    'new ingredient searchable without waiting for base cache TTL',
  );
  final data =
      (await store.firestore
              .doc('catalogs/ingredients/additions/${addition.id}')
              .get())
          .data()!;
  check(
    !data.containsKey('kcal') &&
        !data.containsKey('uid') &&
        !data.containsKey('grams'),
    'shared discovery contains only ingredient name and provenance',
  );
  final journal = FirestoreKitchenRepository(
    store: store,
    collection: 'nutrition_logs',
    decode: NutritionEntry.fromJson,
  );
  const entry = NutritionEntry(
    id: '55555555555555555555555555555555',
    title: 'Bữa SDK',
    day: '2026-11-27',
    slot: MealSlot.lunch,
    servings: 2,
    consumedServings: 1,
    catalogVersion: 'USDA-SR-Legacy-2018-04',
    lines: [
      NutritionLine(
        id: 'egg',
        name: 'Trứng',
        foodId: '171287',
        grams: 100,
        confirmed: true,
      ),
    ],
    totals: NutritionTotals(71.5, 6.28, .36, 4.755),
  );
  await journal.createIfAbsent(entry);
  await journal.createIfAbsent(entry);
  check(await journal.count() == 1, 'nutrition log retry saves once');
  check(
    (await journal.find(entry.id))!.totals.kcal == 71.5,
    'nutrition log persistence and codec',
  );
  denied = false;
  try {
    await store.firestore
        .doc('users/${store.uid}/nutrition_logs/${entry.id}')
        .update({'title': 'overwrite'});
  } on FirebaseException {
    denied = true;
  }
  check(denied, 'nutrition history cannot be overwritten');
}
