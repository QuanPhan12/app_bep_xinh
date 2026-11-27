import 'dart:async';

import 'package:app_bep_xinh/features/recipe_search/cubits/recipe_search_cubit.dart';
import 'package:app_bep_xinh/features/recipe_search/models/recipe_search_request.dart';
import 'package:app_bep_xinh/features/recipe_search/services/search_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/recipe_detail_fakes.dart';
import '../../support/recipe_search_fakes.dart';

class _DelayedHistory implements SearchHistoryRepository {
  final pending = Completer<List<String>>();
  @override
  Future<List<String>> read() => pending.future;
  @override
  Future<List<String>> remember(String query) async => [query];
  @override
  Future<void> clear() async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('history persists, deduplicates accents, limits length and isolates accounts', () async {
    final a = LocalSearchHistoryRepository.forUser('account-a');
    final b = LocalSearchHistoryRepository.forUser('account-b');
    final guest = LocalSearchHistoryRepository.forUser(null);
    await a.remember(' Cá   hồi ');
    await a.remember('ca hoi');
    expect(await a.read(), ['ca hoi']);
    for (var i = 0; i < 10; i++) {
      await a.remember('Món $i');
    }
    expect(await a.read(), hasLength(8));
    expect((await a.read()).first, 'Món 9');
    expect(await b.read(), isEmpty);
    expect(await guest.read(), isEmpty);
    expect(
      await LocalSearchHistoryRepository.forUser('account-a').read(),
      await a.read(),
    );
    await a.clear();
    expect(await a.read(), isEmpty);
  });

  test(
    'clear history wins over a late initial read; filter reset preserves query',
    () async {
      final history = _DelayedHistory(),
          favorites = StubRecipeFavoritesService();
      final cubit = RecipeSearchCubit(
        service: StubRecipeSearchService(),
        favorites: favorites,
        history: history,
      );
      addTearDown(cubit.close);
      addTearDown(favorites.dispose);
      final old = cubit.loadHistory();
      await cubit.clearHistory();
      history.pending.complete(['cũ']);
      await old;
      expect(cubit.state.recentQueries, isEmpty);
      await cubit.applyFilters(
        const RecipeSearchRequest(
          maxMinutes: 30,
          difficulty: RecipeDifficulty.easy,
          excludedIngredients: 'tôm',
        ),
      );
      cubit.changeQuery('canh');
      expect(cubit.state.request.maxMinutes, 30);
      await cubit.selectFilter(RecipeSearchFilter.soup);
      expect(cubit.state.request.excludedIngredients, 'tôm');
      await cubit.clearFilters();
      expect(cubit.state.request, const RecipeSearchRequest(query: 'canh'));
      await cubit.selectRecent('Cá hồi');
      expect(cubit.state.request.query, 'Cá hồi');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.recentQueries, ['Cá hồi']);
    },
  );
}
