import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:app_bep_xinh/features/recipe_search/cubits/recipe_search_cubit.dart';
import 'package:app_bep_xinh/features/recipe_search/models/recipe_search_request.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../../support/mock_services.dart';
import '../../support/recipe_detail_fakes.dart';
import '../../support/recipe_search_fakes.dart';

void main() {
  late StubRecipeSearchService service;
  late StubRecipeFavoritesService favorites;
  late RecipeSearchCubit cubit;
  setUp(() {
    service = StubRecipeSearchService();
    favorites = StubRecipeFavoritesService();
    cubit = RecipeSearchCubit(
      service: service,
      favorites: favorites,
      debounce: const Duration(milliseconds: 10),
    );
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
    await favorites.dispose();
  });

  test(
    'debounces typing and discards out-of-order results across filter changes',
    () async {
      final pending = <Completer<List<RecipeItem>>>[];
      service.onSearch = (_) {
        final task = Completer<List<RecipeItem>>();
        pending.add(task);
        return task.future;
      };
      cubit.changeQuery('c');
      cubit.changeQuery('ca');
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(service.requests, [const RecipeSearchRequest(query: 'ca')]);
      final latest = cubit.selectFilter(RecipeSearchFilter.eatClean);
      expect(
        service.requests.last,
        const RecipeSearchRequest(
          query: 'ca',
          filter: RecipeSearchFilter.eatClean,
        ),
      );
      pending.last.complete([homeFixture().recipes.last]);
      await latest;
      pending.first.complete([homeFixture().recipes.first]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.recipes.single.id, homeFixture().recipes.last.id);
    },
  );

  test(
    'clear cancels debounce, keeps filter, and allows retyping the same query',
    () async {
      await cubit.selectFilter(RecipeSearchFilter.soup);
      cubit.changeQuery('canh');
      await cubit.clearQuery();
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(
        service.requests.last,
        const RecipeSearchRequest(filter: RecipeSearchFilter.soup),
      );
      expect(service.requests, hasLength(2));
      cubit.changeQuery('canh');
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(service.requests.last.query, 'canh');
      expect(cubit.state.status, RecipeSearchStatus.ready);
    },
  );

  test('failure retries latest request and stale failure cannot replace new results', () async {
    service.onSearch = (_) async => throw StateError('offline');
    await cubit.load();
    expect(cubit.state.status, RecipeSearchStatus.failure);
    service.onSearch = (_) async => homeFixture().recipes;
    await cubit.load();
    expect(cubit.state.status, RecipeSearchStatus.ready);
    final old = Completer<List<RecipeItem>>();
    service.onSearch = (_) => old.future;
    final oldTask = cubit.load();
    service.onSearch = (_) async => [];
    await cubit.selectFilter(RecipeSearchFilter.vegetarian);
    old.completeError(StateError('stale'));
    await oldTask;
    expect(cubit.state.status, RecipeSearchStatus.ready);
    expect(cubit.state.recipes, isEmpty);
  });

  test('favorite writes lock per recipe and updates arriving during search survive response', () async {
    await cubit.load();
    final id = cubit.state.recipes.first.id;
    final write = Completer<void>();
    favorites.onSet = (_, _) => write.future;
    final task = cubit.toggleFavorite(id);
    await cubit.toggleFavorite(id);
    expect(favorites.writes, 1);
    write.complete();
    await task;
    expect(cubit.state.recipes.first.isFavorite, isTrue);
    final pending = Completer<List<RecipeItem>>();
    service.onSearch = (_) => pending.future;
    final search = cubit.load();
    favorites.controller.add(RecipeFavoriteChange(id, false));
    await Future<void>.delayed(Duration.zero);
    pending.complete(
      homeFixture().recipes.map((r) => r.copyWith(isFavorite: true)).toList(),
    );
    await search;
    expect(cubit.state.recipes.first.isFavorite, isFalse);
  });

  test('closing cancels debounce and safely ignores late completion', () async {
    cubit.changeQuery('later');
    await cubit.close();
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(service.requests, isEmpty);
    cubit = RecipeSearchCubit(service: service, favorites: favorites);
    final pending = Completer<List<RecipeItem>>();
    service.onSearch = (_) => pending.future;
    final task = cubit.load();
    await cubit.close();
    pending.completeError(StateError('late'));
    await task;
  });
}
