import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/core/utils/async_serial_queue.dart';
import 'package:app_bep_xinh/features/fridge/models/fridge_summary.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';

import '../models/home_data.dart';

abstract interface class HomeService {
  Stream<FridgeSummary> get fridgeSummaries;
  Future<HomeData> fetchHome();
  Future<void> setFavorite(String recipeId, bool isFavorite);
}

class MockHomeService implements HomeService {
  final MockApiClient api;
  final FridgeService fridgeService;
  final _writes = AsyncSerialQueue();
  final Map<String, bool> _favorites = {};

  MockHomeService(this.api, this.fridgeService);

  @override
  Stream<FridgeSummary> get fridgeSummaries => fridgeService.summaries;

  @override
  Future<HomeData> fetchHome() async {
    await _writes.settled;
    final (json, fridge) = await (
      api.get('home'),
      fridgeService.fetchFridge(),
    ).wait;
    final data = HomeData.fromJson(json, FridgeSummary.fromData(fridge));
    return data.withRecipes(
      data.recipes
          .map(
            (recipe) => _favorites.containsKey(recipe.id)
                ? recipe.copyWith(isFavorite: _favorites[recipe.id])
                : recipe,
          )
          .toList(),
    );
  }

  @override
  Future<void> setFavorite(String recipeId, bool isFavorite) =>
      _writes.run(() async {
        if (recipeId.trim().isEmpty) {
          throw ArgumentError.value(recipeId, 'recipeId');
        }
        await api.simulateWrite();
        _favorites[recipeId] = isFavorite;
      });
}
