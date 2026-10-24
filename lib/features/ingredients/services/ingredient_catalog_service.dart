import 'package:app_bep_xinh/core/services/mock_api_client.dart';

import '../models/ingredient_catalog.dart';

abstract interface class IngredientCatalogService {
  Future<IngredientCatalog> fetchCatalog();
  Future<List<Ingredient>> search(String query);
}

/// Cùng một danh mục và ID cho Đăng món, Tủ lạnh và đối chiếu nguyên liệu.
class MockIngredientCatalogService implements IngredientCatalogService {
  final MockApiClient api;
  IngredientCatalog? _catalog;
  Future<IngredientCatalog>? _loading;
  MockIngredientCatalogService(this.api);

  @override
  Future<IngredientCatalog> fetchCatalog() {
    final cached = _catalog;
    if (cached != null) return Future.value(cached);
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<IngredientCatalog> _load() async {
    final catalog = IngredientCatalog.fromJson(await api.get('ingredients'));
    _catalog = catalog;
    return catalog;
  }

  @override
  Future<List<Ingredient>> search(String query) async {
    final catalog = await fetchCatalog();
    await api.simulateRequest();
    return List.unmodifiable(
      catalog.ingredients.where((item) => item.matches(query)),
    );
  }
}
