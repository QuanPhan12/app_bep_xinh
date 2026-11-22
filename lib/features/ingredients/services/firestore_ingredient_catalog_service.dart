import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ingredient_catalog.dart';
import 'ingredient_catalog_service.dart';

/// Tải nguyên một snapshot để nhóm, đơn vị và nguyên liệu luôn cùng phiên bản.
class FirestoreIngredientCatalogService implements IngredientCatalogService {
  final Future<Map<String, dynamic>?> Function() readDocument;
  final DateTime Function() _now;
  final Duration cacheDuration;
  IngredientCatalog? _catalog;
  DateTime? _loadedAt;
  Future<IngredientCatalog>? _loading;

  FirestoreIngredientCatalogService(
    FirebaseFirestore firestore, {
    this.cacheDuration = const Duration(minutes: 15),
  }) : readDocument = (() async =>
           (await firestore.doc('catalogs/ingredients').get()).data()),
       _now = DateTime.now;

  // Cho test inject dữ liệu biên và đồng hồ mà không phải khởi tạo SDK.
  FirestoreIngredientCatalogService.withReader({
    required this.readDocument,
    DateTime Function()? now,
    this.cacheDuration = const Duration(minutes: 15),
  }) : _now = now ?? DateTime.now;

  @override
  Future<IngredientCatalog> fetchCatalog() {
    final cached = _catalog;
    if (cached != null && _now().difference(_loadedAt!) < cacheDuration) {
      return Future.value(cached);
    }
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<IngredientCatalog> _load() async {
    final data = await readDocument();
    if (data == null || data['schemaVersion'] != 1) {
      throw const FormatException('Ingredient catalog not published');
    }
    final catalog = IngredientCatalog.fromJson(data);
    _catalog = catalog;
    _loadedAt = _now();
    return catalog;
  }

  @override
  Future<List<Ingredient>> search(String query) async {
    final catalog = await fetchCatalog();
    return List.unmodifiable(
      catalog.ingredients.where((item) => item.matches(query)),
    );
  }
}
