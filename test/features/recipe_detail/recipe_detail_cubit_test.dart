import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/features/recipe_detail/cubits/recipe_detail/recipe_detail_cubit.dart';
import 'package:app_bep_xinh/features/recipe_detail/models/recipe_detail.dart';
import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';

import '../../support/recipe_detail_fakes.dart';

void main() {
  late StubRecipeDetailService service;
  late StubRecipeFavoritesService favorites;
  late RecipeDetailCubit cubit;
  setUp(() {
    service = StubRecipeDetailService();
    favorites = StubRecipeFavoritesService();
    cubit = RecipeDetailCubit(
      recipeId: 'bo_ne_tieu_den',
      service: service,
      favorites: favorites,
    );
  });
  tearDown(() async {
    await cubit.close();
    await favorites.dispose();
  });

  test('load deduplicates, retries and ignores results after close', () async {
    final pending = Completer<RecipeDetailData>();
    service.onFetch = (_) => pending.future;
    final task = cubit.load();
    expect(identical(task, cubit.load()), isTrue);
    expect(service.calls, 1);
    pending.completeError(StateError('offline'));
    await task;
    expect(cubit.state.status, RecipeDetailStatus.failure);
    service.onFetch = null;
    await cubit.load();
    expect(cubit.state.status, RecipeDetailStatus.ready);
    expect(cubit.state.recipe!.id, 'bo_ne_tieu_den');
    final other = RecipeDetailCubit(
      recipeId: 'other',
      service: service,
      favorites: favorites,
    );
    final lateResult = Completer<RecipeDetailData>();
    service.onFetch = (_) => lateResult.future;
    final loading = other.load();
    await other.close();
    lateResult.complete(detailDataFixture());
    await expectLater(loading, completes);
  });
  test(
    'unknown id has its own state, without falling back to another dish',
    () async {
      service.onFetch = (_) => Future.error(const RecipeNotFoundException());
      await cubit.load();
      expect(cubit.state.status, RecipeDetailStatus.notFound);
      expect(cubit.state.recipe, isNull);
    },
  );
  test('servings scale numeric amounts without changing original data and pantry initializes checks', () async {
    await cubit.load();
    expect(cubit.state.checkedIngredients, {'egg'});
    cubit.changeServings(3);
    expect(
      cubit.state.recipe!.ingredients.first.quantity(cubit.state.quantityRatio),
      '450 g',
    );
    expect(cubit.state.recipe!.ingredients.first.amount, 300);
    cubit.changeServings(0);
    expect(cubit.state.servings, 1);
    cubit.changeServings(100);
    expect(cubit.state.servings, 50);
    cubit.toggleIngredient('beef');
    expect(cubit.state.checkedIngredients, contains('beef'));
    cubit.toggleIngredient('unknown');
    expect(cubit.state.checkedIngredients, isNot(contains('unknown')));
    cubit.toggleAllIngredients();
    expect(
      cubit.state.checkedIngredients.length,
      cubit.state.recipe!.ingredients.length,
    );
    cubit.toggleAllIngredients();
    expect(cubit.state.checkedIngredients, isEmpty);
  });
  test(
    'favorite writes deduplicate, fail without changing value and retry',
    () async {
      await cubit.load();
      final pending = Completer<void>();
      favorites.onSet = (_, _) => pending.future;
      final task = cubit.toggleFavorite();
      await cubit.toggleFavorite();
      expect(favorites.writes, 1);
      pending.completeError(StateError('offline'));
      await task;
      expect(cubit.state.savingFavorite, isFalse);
      expect(cubit.state.isFavorite, isFalse);
      expect(cubit.state.message, contains('Chưa lưu'));
      favorites.onSet = null;
      await cubit.toggleFavorite();
      expect(cubit.state.isFavorite, isTrue);
    },
  );
  test('favorite changes received during load take precedence over an old snapshot', () async {
    final pending = Completer<RecipeDetailData>();
    service.onFetch = (_) => pending.future;
    final task = cubit.load();
    await favorites.setFavorite('bo_ne_tieu_den', true);
    await Future<void>.value();
    pending.complete(detailDataFixture());
    await task;
    expect(cubit.state.isFavorite, isTrue);
  });
  test(
    'cooking can pause to inspect ingredients, move backwards and complete',
    () async {
      await cubit.load();
      cubit.startCooking();
      expect(cubit.state.tab, RecipeDetailTab.steps);
      expect(cubit.state.cookingStep, 0);
      cubit.previousStep();
      expect(cubit.state.cookingStep, 0);
      cubit.nextStep();
      expect(cubit.state.cookingStep, 1);
      cubit.selectTab(RecipeDetailTab.ingredients);
      cubit.startCooking();
      expect(cubit.state.cookingStep, 1);
      cubit.previousStep();
      expect(cubit.state.cookingStep, 0);
      for (var i = 0; i < cubit.state.recipe!.steps.length; i++) {
        cubit.nextStep();
      }
      expect(cubit.state.cookingStep, isNull);
      expect(cubit.state.noticeId, 1);
    },
  );
}
