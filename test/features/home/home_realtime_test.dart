import 'dart:async';

import 'package:app_bep_xinh/features/home/cubits/home/home.dart';
import 'package:app_bep_xinh/features/home/models/home_feed.dart';
import 'package:app_bep_xinh/features/home/models/home_data.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';
import 'package:app_bep_xinh/features/recipes/services/published_recipe_source.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_image.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_services.dart';
import '../../support/recipe_editor_fakes.dart';

class _LiveHome extends StubHomeService implements HomeRealtimeSource {
  final updates = StreamController<HomeFeed>.broadcast();
  @override
  Stream<HomeFeed> watchFeed() => updates.stream;
}

class _Published extends Fake implements PublishedRecipeSource {
  final recipes = StreamController<List<Map<String, dynamic>>>.broadcast();
  final banners = StreamController<List<Map<String, dynamic>>>.broadcast();
  @override
  Stream<List<Map<String, dynamic>>> watchPublished() => recipes.stream;
  @override
  Stream<List<Map<String, dynamic>>> watchBanners() => banners.stream;
}

class _Favorites extends Fake implements RecipeFavoritesService {
  final events = StreamController<RecipeFavoriteChange>.broadcast();
  Future<bool> Function()? read;
  @override
  Stream<RecipeFavoriteChange> get changes => events.stream;
  @override
  Future<bool> isFavorite(String id, {required bool fallback}) async =>
      await read?.call() ?? false;
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('live feed survives stale refresh, preserves filters and removes deleted content', () async {
    final service = _LiveHome();
    final cubit = HomeCubit(service: service);
    addTearDown(service.updates.close);
    addTearDown(cubit.close);
    await cubit.loadHome();
    final category = cubit.state.data!.categories.first.id;
    cubit.selectCategory(category);
    final pending = Completer<HomeData>();
    service.onFetch = () => pending.future;
    final refresh = cubit.refreshHome();
    final feed = HomeFeed(recipes: [homeFixture().recipes.last], banners: []);
    service.updates.add(feed);
    await settle();
    pending.complete(homeFixture());
    await refresh;
    expect(cubit.state.recipes, feed.recipes);
    expect(cubit.state.data!.banners, isEmpty);
    expect(cubit.state.selectedCategory, category);
    service.updates.addError(StateError('offline'));
    await settle();
    expect(cubit.state.recipes, feed.recipes);
    expect(cubit.state.errorMessage, isNotNull);
    service.updates.add(HomeFeed(recipes: [], banners: []));
    await settle();
    expect(cubit.state.recipes, isEmpty);
    expect(cubit.state.errorMessage, isNull);
    await cubit.close();
    expect(service.updates.hasListener, isFalse);
  });

  test('stream snapshot arriving before first fetch is applied after initialization', () async {
    final service = _LiveHome();
    final pending = Completer<HomeData>();
    service.onFetch = () => pending.future;
    final cubit = HomeCubit(service: service);
    addTearDown(service.updates.close);
    addTearDown(cubit.close);
    final loading = cubit.loadHome();
    service.updates.add(HomeFeed(recipes: [], banners: []));
    await settle();
    pending.complete(homeFixture());
    await loading;
    expect(cubit.state.recipes, isEmpty);
    expect(cubit.state.data!.banners, isEmpty);
  });

  test('home stream joins queries, ignores late conversion and cancels all listeners', () async {
    final published = _Published();
    final favorites = _Favorites();
    addTearDown(published.recipes.close);
    addTearDown(published.banners.close);
    addTearDown(favorites.events.close);
    final service = MockHomeService(
      fixtureApi(),
      StubFridgeService(),
      favorites,
      published: published,
    );
    final events = <HomeFeed>[];
    final subscription = service.watchFeed().listen(events.add);
    final recipe = {
      'id': 'r_live',
      ...validRecipeDraft()
          .copyWith(
            cover: const RecipeImage.remote(
              id: 'cover',
              url: 'https://res.cloudinary.com/ddqouziau/image/upload/v1/live.jpg',
              publicId: 'live',
            ),
          )
          .toRecipeContent()
          .toJson(),
    };
    final stale = Completer<bool>();
    favorites.read = () => stale.future;
    published.recipes.add([recipe]);
    published.banners.add([]);
    await settle();
    published.recipes.add([]);
    await settle();
    stale.complete(false);
    await settle();
    expect(events.last.recipes, isEmpty);
    favorites.read = null;
    published.recipes.add([recipe]);
    published.banners.add([recipe]);
    await settle();
    expect(events.last.recipes.single.id, 'r_live');
    expect(events.last.banners.single.id, 'r_live');
    published.banners.add([]);
    await settle();
    expect(events.last.banners, isEmpty);
    expect(events.last.recipes, hasLength(1));
    await subscription.cancel();
    expect(published.recipes.hasListener, isFalse);
    expect(published.banners.hasListener, isFalse);
    expect(favorites.events.hasListener, isFalse);
  });
}
