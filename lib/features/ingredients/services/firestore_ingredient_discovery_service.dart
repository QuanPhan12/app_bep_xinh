import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_user_store.dart';
import 'ingredient_catalog_service.dart';
import 'ingredient_discovery_service.dart';

class FirestoreIngredientDiscoveryService
    implements IngredientDiscoveryService {
  final FirestoreUserStore store;
  final IngredientCatalogService catalog;
  const FirestoreIngredientDiscoveryService(this.store, this.catalog);

  @override
  Future<void> saveDiscovered(String requestId, Iterable<String> names) async {
    store.checkSession();
    final current = await catalog.fetchCatalog();
    store.checkSession();
    final existing = {
      for (final item in current.ingredients)
        for (final name in [item.name, ...item.aliases])
          ingredientNameKey(name),
    };
    final additions = <String, String>{};
    for (final raw in names) {
      final name = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (name.isEmpty ||
          name.length > 80 ||
          RegExp(r'[\x00-\x1f\x7f]').hasMatch(name)) {
        throw const FormatException('Tên nguyên liệu AI không hợp lệ.');
      }
      if (existing.add(ingredientNameKey(name))) {
        additions[discoveredIngredientId(name)] = name;
      }
    }
    if (additions.length > 30) {
      throw const FormatException('Quá nhiều nguyên liệu.');
    }
    if (additions.isEmpty) return;
    await store.firestore.runTransaction((tx) async {
      final refs = additions.keys
          .map(
            (id) => store.firestore.doc('catalogs/ingredients/additions/$id'),
          )
          .toList();
      final snapshots = await Future.wait(refs.map(tx.get));
      store.checkSession();
      // Chỉ tạo tên mới; transaction giữ nguyên bản ghi nếu nhiều máy nhận ra cùng lúc.
      for (var i = 0; i < refs.length; i++) {
        if (snapshots[i].exists) continue;
        final name = additions[refs[i].id]!;
        tx.set(refs[i], {
          'schemaVersion': 1,
          'name': name,
          'nameKey': ingredientNameKey(name),
          'source': 'nutrition_ai',
          'requestId': requestId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
    store.checkSession();
  }
}
