import 'package:app_bep_xinh/features/fridge/cubits/fridge/fridge_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_services.dart';

void main() {
  late FridgeCubit cubit;

  setUp(() async {
    cubit = FridgeCubit(service: createMockFridgeService());
    await cubit.loadFridge();
  });
  tearDown(() => cubit.close());

  test(
    'matching uses actual ingredients and moves a recipe between groups',
    () async {
      expect(cubit.state.readyRecipes.map((item) => item.id), [
        'tofu_tomato',
        'egg_tomato_soup',
      ]);
      expect(cubit.state.almostReadyRecipes.map((item) => item.id), [
        'beef_tomato',
      ]);

      final previous = cubit.state;
      await cubit.toggleIngredient('beef');
      expect(
        cubit.state.readyRecipes.map((item) => item.id),
        contains('beef_tomato'),
      );
      expect(cubit.state.almostReadyRecipes, isEmpty);
      expect(previous.selectedIds, isNot(contains('beef')));
      expect(
        () => cubit.state.selectedIds.add('garlic'),
        throwsUnsupportedError,
      );

      await cubit.removeIngredient('tomato');
      expect(cubit.state.readyRecipes, isEmpty);
      expect(cubit.state.almostReadyRecipes.length, 3);
      for (final recipe in cubit.state.almostReadyRecipes) {
        expect(recipe.missingIngredients(cubit.state.selectedIds), ['tomato']);
      }
    },
  );

  test(
    'clear removes suggestions and selecting again recalculates them',
    () async {
      await cubit.clearIngredients();
      expect(cubit.state.selectedIds, isEmpty);
      expect(cubit.state.readyRecipes, isEmpty);
      expect(cubit.state.almostReadyRecipes, isEmpty);

      for (final id in ['tofu', 'tomato', 'scallion']) {
        await cubit.toggleIngredient(id);
      }
      expect(cubit.state.readyRecipes.single.id, 'tofu_tomato');
      await cubit.toggleIngredient('tofu');
      expect(cubit.state.readyRecipes, isEmpty);
      expect(
        cubit.state.selectedIds.toSet().length,
        cubit.state.selectedIds.length,
      );
      final previous = cubit.state;
      await cubit.toggleIngredient('unknown');
      expect(cubit.state, previous);
    },
  );

  test(
    'search supports accents, clear, and retyping without losing selection',
    () async {
      final selected = cubit.state.selectedIds;
      cubit.searchIngredients('  THIT BO  ');
      expect(cubit.state.visibleIngredients.single.id, 'beef');
      cubit.searchIngredients('');
      expect(cubit.state.visibleIngredients.length, greaterThan(1));
      cubit.searchIngredients('đậu hũ');
      expect(cubit.state.visibleIngredients.single.id, 'tofu');
      cubit.searchIngredients('không có');
      expect(cubit.state.visibleIngredients, isEmpty);
      expect(cubit.state.selectedIds, selected);
    },
  );

  test('quick and vegetarian filters apply to both recipe groups', () async {
    await cubit.toggleIngredient('beef');
    cubit.selectFilter(FridgeRecipeFilter.quick);
    expect(
      cubit.state.readyRecipes.every((item) => item.minutes <= 15),
      isTrue,
    );
    expect(
      cubit.state.readyRecipes.map((item) => item.id),
      isNot(contains('beef_tomato')),
    );
    cubit.selectFilter(FridgeRecipeFilter.vegetarian);
    expect(cubit.state.readyRecipes.single.id, 'tofu_tomato');
    expect(
      cubit.state.almostReadyRecipes.every((item) => item.isVegetarian),
      isTrue,
    );
    await cubit.removeIngredient('tofu');
    expect(cubit.state.readyRecipes, isEmpty);
    expect(cubit.state.almostReadyRecipes.single.id, 'tofu_tomato');
  });
}
