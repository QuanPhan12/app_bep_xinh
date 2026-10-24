import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/core/utils/async_serial_queue.dart';

import '../models/recipe_draft.dart';
import '../validation/recipe_editor_validation.dart';

abstract interface class RecipeEditorService {
  Future<RecipeDraft?> loadDraft();
  Future<void> saveDraft(RecipeDraft draft);
  Future<void> submit(RecipeDraft draft);
}

/// Chỉ mô phỏng backend trong phiên, không công bố bài viết ra hệ thống thật.
class MockRecipeEditorService implements RecipeEditorService {
  final MockApiClient api;
  final IngredientCatalogService catalogService;
  final _writes = AsyncSerialQueue();
  RecipeDraft? _draft;

  MockRecipeEditorService(this.api, this.catalogService);

  @override
  Future<RecipeDraft?> loadDraft() async {
    await _writes.settled;
    await api.simulateRequest();
    return _draft;
  }

  @override
  Future<void> saveDraft(RecipeDraft draft) => _writes.run(() async {
    await api.simulateWrite();
    _draft = draft;
  });

  @override
  Future<void> submit(RecipeDraft draft) => _writes.run(() async {
    final normalized = draft.normalized();
    if (RecipeEditorValidation.validate(normalized).isNotEmpty) {
      throw const FormatException('Invalid recipe');
    }
    final catalog = await catalogService.fetchCatalog();
    for (final item in normalized.ingredients) {
      final ingredient = item.ingredientId == null
          ? null
          : catalog.byId[item.ingredientId];
      if (item.ingredientId != null && ingredient == null) {
        throw const FormatException('Unknown ingredient');
      }
      if (!item.toTaste &&
          (!catalog.unitsById.containsKey(item.unitId) ||
              (ingredient != null &&
                  !ingredient.unitIds.contains(item.unitId)))) {
        throw const FormatException('Invalid ingredient unit');
      }
    }
    await api.simulateWrite();
    _draft = null;
  });
}
