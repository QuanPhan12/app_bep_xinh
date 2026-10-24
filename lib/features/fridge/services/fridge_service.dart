import 'dart:async';

import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/core/utils/async_serial_queue.dart';

import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';

import '../models/fridge_data.dart';
import '../models/fridge_summary.dart';

abstract interface class FridgeService {
  /// Phát sau khi server xác nhận để các màn dùng chung không bị lệch dữ liệu.
  Stream<FridgeSummary> get summaries;
  Future<FridgeData> fetchFridge();
  Future<void> saveInventory(List<String> selectedIds);
  Future<void> dispose();
}

/// Backend giả lập giữ dữ liệu trong phiên; triển khai API thật thay qua interface.
class MockFridgeService implements FridgeService {
  final MockApiClient api;
  final IngredientCatalogService catalogService;
  final _writes = AsyncSerialQueue();
  final _summaries = StreamController<FridgeSummary>.broadcast();
  List<String>? _inventory;
  FridgeData? _current;
  Future<FridgeData>? _readTask;
  bool _disposed = false;

  MockFridgeService(this.api, this.catalogService);

  @override
  Stream<FridgeSummary> get summaries => _summaries.stream;

  @override
  Future<FridgeData> fetchFridge() async {
    _ensureActive();
    await _writes.settled;
    return _readTask ??= _read().whenComplete(() => _readTask = null);
  }

  Future<FridgeData> _read() async {
    final catalog = await catalogService.fetchCatalog();
    final response = FridgeData.fromJson(
      await api.get('fridge'),
      ingredients: catalog.ingredients,
    );
    _ensureActive();
    final data = response.withInventory(
      (_inventory ?? response.selectedIds)
          .where(response.ingredientsById.containsKey)
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
      if (snapshot.any((id) => !data.ingredientsById.containsKey(id))) {
        throw ArgumentError.value(
          snapshot,
          'selectedIds',
          'Unknown ingredient',
        );
      }
      await api.simulateWrite();
      _ensureActive();
      _inventory = snapshot;
      _publish((_current ?? data).withInventory(snapshot));
    });
  }

  void _publish(FridgeData data) {
    final previous = _current;
    _current = data;
    final summary = FridgeSummary.fromData(data);
    if (previous == null || FridgeSummary.fromData(previous) != summary) {
      _summaries.add(summary);
    }
  }

  void _ensureActive() {
    if (_disposed) throw StateError('FridgeService has been disposed');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _summaries.close();
  }
}
