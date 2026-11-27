import 'package:app_bep_xinh/features/recipe_reports/services/recipe_report_repository.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:app_bep_xinh/features/kitchen/models/kitchen_entry.dart';
import 'package:app_bep_xinh/features/kitchen/services/kitchen_local_storage.dart';
import 'package:app_bep_xinh/features/kitchen/services/kitchen_repository.dart';
import 'package:app_bep_xinh/features/kitchen/services/kitchen_services.dart';
import 'package:app_bep_xinh/features/cooking_timers/services/cooking_timer_service.dart';
import 'package:app_bep_xinh/features/offline_recipes/services/offline_recipe_service.dart';
import 'package:app_bep_xinh/features/following/services/following_feed_service.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:app_bep_xinh/features/recipe_reviews/services/recipe_review_repository.dart';
import 'package:app_bep_xinh/features/recipe_sharing/services/recipe_sharing_service.dart';
import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';
import 'package:app_bep_xinh/features/recipe_search/services/recipe_search_service.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import 'mock_services.dart';

class MemoryKitchenStorage implements KitchenLocalStorage {
  final data = <String, String>{};
  bool fail = false;
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async {
    if (fail) throw StateError('storage failed');
    data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    data.remove(key);
  }
}

class MemoryKitchenRepository<T extends KitchenEntry>
    implements KitchenRepository<T> {
  final items = <String, T>{};
  final _changes = StreamController<List<T>>.broadcast(sync: true);
  bool fail = false;
  void _emit() => _changes.add(items.values.toList());
  @override
  Stream<List<T>> watch() async* {
    yield items.values.toList();
    yield* _changes.stream;
  }

  @override
  Future<List<T>> fetch() async => items.values.toList();
  @override
  Future<int> count() async => items.length;
  @override
  Future<void> save(T value) async {
    if (fail) throw StateError('write failed');
    value.toJson();
    items[value.id] = value;
    _emit();
  }

  @override
  Future<void> update(String id, T Function(T) change) async =>
      save(change(items[id]!));
  @override
  Future<void> delete(String id) async {
    if (fail) throw StateError('write failed');
    items.remove(id);
    _emit();
  }

  Future<void> dispose() => _changes.close();
}

class FakeKitchenReviews extends Fake implements RecipeReviewRepository {
  @override
  String get uid => 'alice';
  @override
  Future<ReviewPage> page(String recipeId, {String? after}) async =>
      const ReviewPage([], null);
  @override
  Future<RecipeReview?> own(String recipeId) async => null;
  @override
  Stream<RatingSummary> ratings(String recipeId) =>
      Stream.value(const RatingSummary());
}

class FakeKitchenSearch extends Fake implements RecipeSearchService {}

class FakeFollowingFeed extends Fake implements FollowingFeedService {
  @override
  bool get hasMore => false;
  @override
  Future<List<RecipeItem>> next(
    List<FollowedAuthor> authors, {
    bool reset = false,
  }) async => [];
}

KitchenServices kitchenFixture({
  RecipeReviewRepository? reviews,
  RecipeReportRepository? reports,
  MemoryKitchenStorage? storage,
  RecipeDetailService? details,
  CookingTimerService? timers,
}) {
  final api = fixtureApi(),
      catalog = MockIngredientCatalogService(fixtureApi());
  final fridge = createMockFridgeService();
  final local = storage ?? MemoryKitchenStorage();
  return KitchenServices(
    uid: 'alice',
    reports: reports,
    meals: MemoryKitchenRepository<MealPlanEntry>(),
    collections: MemoryKitchenRepository<RecipeCollection>(),
    journal: MemoryKitchenRepository<CookingLog>(),
    pantry: MemoryKitchenRepository<PantryLot>(),
    following: MemoryKitchenRepository<FollowedAuthor>(),
    timers:
        timers ??
        CookingTimerService(
          storage: local,
          storageKey: 'alice.timer',
          checkSession: () {},
        ),
    offline: OfflineRecipeService(
      storage: local,
      storageKey: 'alice.offline',
      checkSession: () {},
      isPublished: (_) async => true,
      client: MockClient((_) async => http.Response('', 404)),
    ),
    reviews: reviews ?? FakeKitchenReviews(),
    createFeed: () => FakeFollowingFeed(),
    sharing: RecipeSharingService(),
    search: FakeKitchenSearch(),
    details:
        details ??
        MockRecipeDetailService(
          api,
          catalog,
          fridge,
          MockRecipeFavoritesService(api),
        ),
    catalog: catalog,
    fridge: fridge,
  );
}

Future<void> disposeKitchen(KitchenServices services) async {
  services.timers.dispose();
  for (final repository in [
    services.meals,
    services.collections,
    services.journal,
    services.pantry,
    services.following,
  ]) {
    await (repository as MemoryKitchenRepository).dispose();
  }
  services.fridge.dispose();
}
