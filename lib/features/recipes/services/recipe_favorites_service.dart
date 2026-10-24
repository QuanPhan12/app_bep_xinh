import 'dart:async';

import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/core/utils/async_serial_queue.dart';

class RecipeFavoriteChange {
  final String recipeId;
  final bool isFavorite;
  const RecipeFavoriteChange(this.recipeId, this.isFavorite);
}

abstract interface class RecipeFavoritesService {
  Stream<RecipeFavoriteChange> get changes;
  Future<bool> isFavorite(String recipeId, {required bool fallback});
  Future<void> setFavorite(String recipeId, bool value);
  Future<void> dispose();
}

/// Một nguồn yêu thích dùng chung cho Home và Chi tiết món trong phiên mock.
class MockRecipeFavoritesService implements RecipeFavoritesService {
  final MockApiClient api;
  final _writes = AsyncSerialQueue();
  final _values = <String, bool>{};
  final _changes = StreamController<RecipeFavoriteChange>.broadcast();
  bool _disposed = false;
  MockRecipeFavoritesService(this.api);
  @override
  Stream<RecipeFavoriteChange> get changes => _changes.stream;
  @override
  Future<bool> isFavorite(String recipeId, {required bool fallback}) async {
    await _writes.settled;
    return _values[recipeId] ?? fallback;
  }

  @override
  Future<void> setFavorite(String recipeId, bool value) =>
      _writes.run(() async {
        if (_disposed) throw StateError('Favorites service disposed');
        if (recipeId.trim().isEmpty) {
          throw ArgumentError.value(recipeId, 'recipeId');
        }
        await api.simulateWrite();
        if (_disposed) throw StateError('Favorites service disposed');
        _values[recipeId] = value;
        _changes.add(RecipeFavoriteChange(recipeId, value));
      });
  @override
  Future<void> dispose() async {
    _disposed = true;
    await _changes.close();
  }
}
