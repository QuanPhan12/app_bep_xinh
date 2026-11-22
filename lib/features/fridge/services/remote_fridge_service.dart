import 'dart:async';

import '../../../core/utils/async_serial_queue.dart';
import '../../ingredients/services/ingredient_catalog_service.dart';
import '../models/fridge_data.dart';
import '../models/fridge_recipe.dart';
import '../models/fridge_summary.dart';
import 'fridge_inventory_repository.dart';
import 'fridge_service.dart';

class RemoteFridgeService implements FridgeService {
  final FridgeInventoryRepository inventory;
  final IngredientCatalogService catalog;
  final Future<List<Map<String, dynamic>>> Function() readPublished;
  final _writes = AsyncSerialQueue();
  final _summaries = StreamController<FridgeSummary>.broadcast();
  FridgeData? _current;
  Future<FridgeData>? _reading;
  bool _disposed = false;

  RemoteFridgeService({
    required this.inventory,
    required this.catalog,
    required this.readPublished,
  });

  @override
  Stream<FridgeSummary> get summaries => _summaries.stream;

  void _ensureActive() {
    if (_disposed) throw StateError('Fridge service disposed');
  }

  @override
  Future<FridgeData> fetchFridge() async {
    _ensureActive();
    await _writes.settled;
    _ensureActive();
    return _reading ??= _read().whenComplete(() => _reading = null);
  }

  Future<FridgeData> _read() async {
    final (ingredients, selected, published) = await (
      catalog.fetchCatalog(),
      inventory.read(),
      readPublished(),
    ).wait;
    final data = FridgeData(
      ingredients: ingredients.ingredients,
      recipes: published
          .map((json) => FridgeRecipe.fromPublished(json, ingredients))
          .toList(),
      // ID bị gỡ khỏi catalog không làm hỏng màn hình hoặc được tự chọn lại.
      selectedIds: selected
          .where(ingredients.byId.containsKey)
          .toSet()
          .toList(),
    );
    _publish(data);
    return data;
  }

  @override
  Future<void> saveInventory(List<String> selectedIds) {
    final snapshot = List<String>.unmodifiable(selectedIds.toSet());
    return _writes.run(() async {
      _ensureActive();
      final data = _current ?? await _read();
      if (snapshot.length > 500 ||
          snapshot.any((id) => !data.ingredientsById.containsKey(id))) {
        throw ArgumentError('Unknown ingredient or inventory too large');
      }
      await inventory.save(snapshot);
      // Chỉ phát dữ liệu đã được server xác nhận; Cubit tự rollback khi ghi lỗi.
      _publish(data.withInventory(snapshot));
    });
  }

  void _publish(FridgeData data) {
    _ensureActive();
    final previous = _current;
    _current = data;
    final summary = FridgeSummary.fromData(data);
    if (previous == null || FridgeSummary.fromData(previous) != summary) {
      _summaries.add(summary);
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _summaries.close();
  }
}
