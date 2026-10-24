import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';

import 'dart:convert';
import 'dart:io';

import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/features/fridge/models/fridge_data.dart';
import 'package:app_bep_xinh/features/fridge/models/fridge_summary.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';
import 'package:app_bep_xinh/features/home/models/home_data.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';
import 'package:flutter/services.dart';

Map<String, dynamic> fixtureJson(String name) =>
    jsonDecode(File('assets/mock/$name.json').readAsStringSync())
        as Map<String, dynamic>;

FridgeData fridgeFixture() => FridgeData.fromJson(
  fixtureJson('fridge'),
  ingredients: catalogFixture().ingredients,
);
HomeData homeFixture() => HomeData.fromJson(
  fixtureJson('home'),
  FridgeSummary.fromData(fridgeFixture()),
);

class FixtureAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      File(key).readAsStringSync();

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(File(key).readAsBytesSync());
}

MockApiClient fixtureApi() =>
    MockApiClient(bundle: FixtureAssetBundle(), latency: Duration.zero);
MockFridgeService createMockFridgeService() =>
    MockFridgeService(fixtureApi(), MockIngredientCatalogService(fixtureApi()));

class StubFridgeService implements FridgeService {
  @override
  Stream<FridgeSummary> summaries = const Stream.empty();
  Future<FridgeData> Function()? onFetch;
  Future<void> Function(List<String>)? onSave;

  @override
  Future<FridgeData> fetchFridge() =>
      onFetch?.call() ?? Future.value(fridgeFixture());
  @override
  Future<void> saveInventory(List<String> ids) =>
      onSave?.call(ids) ?? Future.value();

  @override
  Future<void> dispose() async {}
}

class StubHomeService implements HomeService {
  @override
  Stream<RecipeFavoriteChange> favoriteChanges = const Stream.empty();
  @override
  Stream<FridgeSummary> fridgeSummaries = const Stream.empty();
  Future<HomeData> Function()? onFetch;
  Future<void> Function(String, bool)? onFavorite;

  @override
  Future<HomeData> fetchHome() =>
      onFetch?.call() ?? Future.value(homeFixture());
  @override
  Future<void> setFavorite(String id, bool value) =>
      onFavorite?.call(id, value) ?? Future.value();
}

IngredientCatalog catalogFixture() =>
    IngredientCatalog.fromJson(fixtureJson('ingredients'));
