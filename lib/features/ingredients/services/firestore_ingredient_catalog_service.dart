import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ingredient_catalog.dart';
import 'ingredient_catalog_service.dart';
import 'ingredient_discovery_service.dart';

/// Cache snapshot admin cùng nhóm/đơn vị; đọc thêm tên AI khi tải danh mục.
class FirestoreIngredientCatalogService implements IngredientCatalogService {
  final Future<Map<String, dynamic>?> Function() readDocument;
  final Future<List<Map<String, dynamic>>> Function()? readAdditions;
  final DateTime Function() _now;
  final Duration cacheDuration;
  IngredientCatalog? _catalog;
  DateTime? _loadedAt;
  Future<IngredientCatalog>? _loading;
  IngredientCatalog? _merged;
  String? _additionKey;

  FirestoreIngredientCatalogService(
    FirebaseFirestore firestore, {
    this.cacheDuration = const Duration(minutes: 15),
  }) : readDocument = (() async =>
           (await firestore.doc('catalogs/ingredients').get()).data()),
       readAdditions = (() async =>
           (await firestore.collection('catalogs/ingredients/additions').get())
               .docs
               .map((d) => {...d.data(), 'id': d.id})
               .toList()),
       _now = DateTime.now;

  // Cho test inject dữ liệu biên và đồng hồ mà không phải khởi tạo SDK.
  FirestoreIngredientCatalogService.withReader({
    required this.readDocument,
    this.readAdditions,
    DateTime Function()? now,
    this.cacheDuration = const Duration(minutes: 15),
  }) : _now = now ?? DateTime.now;

  @override
  Future<IngredientCatalog> fetchCatalog() {
    final cached = _catalog;
    if (readAdditions == null &&
        cached != null &&
        _now().difference(_loadedAt!) < cacheDuration) {
      return Future.value(cached);
    }
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<IngredientCatalog> _load() async {
    var catalog = _catalog;
    if (catalog == null || _now().difference(_loadedAt!) >= cacheDuration) {
      final data = await readDocument();
      if (data == null || data['schemaVersion'] != 1) {
        throw const FormatException('Ingredient catalog not published');
      }
      catalog = IngredientCatalog.fromJson(data);
      _catalog = catalog;
      _loadedAt = _now();
      _merged = null;
    }
    final additions = await readAdditions?.call() ?? [];
    if (additions.isEmpty) {
      _merged = null;
      return catalog;
    }
    final names = {
      for (final item in catalog.ingredients)
        for (final name in [item.name, ...item.aliases])
          ingredientNameKey(name),
    };
    final extra = <Ingredient>[];
    for (final row in additions) {
      final name = row['name'];
      if (name is! String ||
          name.trim().isEmpty ||
          name.length > 80 ||
          row['id'] != discoveredIngredientId(name) ||
          row['nameKey'] != ingredientNameKey(name) ||
          !names.add(ingredientNameKey(name))) {
        continue;
      }
      extra.add(
        Ingredient(
          id: row['id'] as String,
          name: name,
          group: 'Nguyên liệu khác',
          categoryId: 'ai_other',
          unitIds: catalog.units.map((u) => u.id).toList(),
          defaultUnitId: 'g',
        ),
      );
    }
    extra.sort((a, b) => a.id.compareTo(b.id));
    final key = extra.map((e) => '${e.id}:${e.name}').join('|');
    if (_merged != null && _additionKey == key) return _merged!;
    _additionKey = key;
    return _merged = IngredientCatalog(
      ingredients: [...catalog.ingredients, ...extra],
      units: catalog.units,
      version: catalog.version,
      categories: [
        ...catalog.categories,
        if (extra.isNotEmpty)
          const IngredientCategory(
            id: 'ai_other',
            name: 'Nguyên liệu khác',
            sortOrder: 1000,
          ),
      ],
    );
  }

  @override
  Future<List<Ingredient>> search(String query) async {
    // Picker giữ cùng snapshot khi gõ để kết quả luôn chọn được theo ID đã tải.
    final catalog = readAdditions == null
        ? await fetchCatalog()
        : _merged ?? _catalog ?? await fetchCatalog();
    return List.unmodifiable(
      catalog.ingredients.where((item) => item.matches(query)),
    );
  }
}
