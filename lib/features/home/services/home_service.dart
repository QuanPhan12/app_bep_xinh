import '../../recipes/services/published_recipe_source.dart';
import '../models/recipe_item.dart';
import '../models/home_banner_item.dart';
import '../models/home_feed.dart';

import 'dart:async';

import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:app_bep_xinh/features/fridge/models/fridge_summary.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_service.dart';

import '../models/home_data.dart';

abstract interface class HomeService {
  Stream<FridgeSummary> get fridgeSummaries;
  Stream<RecipeFavoriteChange> get favoriteChanges;
  Future<HomeData> fetchHome();
  Future<void> setFavorite(String recipeId, bool isFavorite);
}

abstract interface class HomeRealtimeSource {
  Stream<HomeFeed> watchFeed();
}

class MockHomeService implements HomeService, HomeRealtimeSource {
  final MockApiClient api;
  final FridgeService fridgeService;
  final RecipeFavoritesService favorites;

  final PublishedRecipeSource? published;
  MockHomeService(
    this.api,
    this.fridgeService,
    this.favorites, {
    this.published,
  });

  @override
  Stream<FridgeSummary> get fridgeSummaries => fridgeService.summaries;

  @override
  Future<HomeData> fetchHome() async {
    final (json, fridge) = await (
      api.get('home'),
      fridgeService.fetchFridge(),
    ).wait;
    final data = HomeData.fromJson(json, FridgeSummary.fromData(fridge));
    final recipes = published != null
        ? <RecipeItem>[]
        : await Future.wait(
            data.recipes.map(
              (recipe) async => recipe.copyWith(
                isFavorite: await favorites.isFavorite(
                  recipe.id,
                  fallback: recipe.isFavorite,
                ),
              ),
            ),
          );
    final remote =
        await published?.fetchPublished() ?? <Map<String, dynamic>>[];
    final approved = await Future.wait(
      remote.map(
        (entry) async => RecipeItem.fromRecipeJson(
          entry,
          isFavorite: await favorites.isFavorite(
            entry['id'] as String,
            fallback: false,
          ),
        ),
      ),
    );
    final result = data.withRecipes(published == null ? recipes : approved);
    final source = published;
    if (source == null) return result;
    final banners = await source.fetchBanners();
    return result.withBanners(
      banners.map(HomeBannerItem.fromRecipeJson).toList(),
    );
  }

  @override
  Stream<HomeFeed> watchFeed() {
    final source = published;
    if (source == null) return const Stream.empty();
    List<Map<String, dynamic>>? recipes;
    List<Map<String, dynamic>>? banners;
    var revision = 0;
    var cancelled = false;
    StreamSubscription<List<Map<String, dynamic>>>? recipeSubscription;
    StreamSubscription<List<Map<String, dynamic>>>? bannerSubscription;
    StreamSubscription<RecipeFavoriteChange>? favoriteSubscription;
    late StreamController<HomeFeed> controller;

    Future<void> publish() async {
      final currentRecipes = recipes;
      final currentBanners = banners;
      if (cancelled || currentRecipes == null || currentBanners == null) return;
      final version = ++revision;
      try {
        final items = await Future.wait(
          currentRecipes.map(
            (entry) async => RecipeItem.fromRecipeJson(
              entry,
              isFavorite: await favorites.isFavorite(
                entry['id'] as String,
                fallback: false,
              ),
            ),
          ),
        );
        if (cancelled || version != revision) return;
        controller.add(
          HomeFeed(
            recipes: items,
            banners: currentBanners.map(HomeBannerItem.fromRecipeJson).toList(),
          ),
        );
      } catch (error, stack) {
        if (!cancelled && version == revision) {
          controller.addError(error, stack);
        }
      }
    }

    void onError(Object error, StackTrace stack) {
      // Giữ snapshot đã hiển thị; không biến lỗi mạng thành một danh sách rỗng.
      if (!cancelled) controller.addError(error, stack);
    }

    controller = StreamController<HomeFeed>(
      onListen: () {
        recipeSubscription = source.watchPublished().listen((value) {
          recipes = value;
          unawaited(publish());
        }, onError: onError);
        bannerSubscription = source.watchBanners().listen((value) {
          banners = value;
          unawaited(publish());
        }, onError: onError);
        favoriteSubscription = favorites.changes.listen(
          (_) => unawaited(publish()),
          onError: onError,
        );
      },
      onCancel: () async {
        cancelled = true;
        revision++;
        await Future.wait([
          if (recipeSubscription != null) recipeSubscription!.cancel(),
          if (bannerSubscription != null) bannerSubscription!.cancel(),
          if (favoriteSubscription != null) favoriteSubscription!.cancel(),
        ]);
      },
    );
    return controller.stream;
  }

  @override
  Stream<RecipeFavoriteChange> get favoriteChanges => favorites.changes;

  @override
  Future<void> setFavorite(String recipeId, bool isFavorite) =>
      favorites.setFavorite(recipeId, isFavorite);
}
