import 'dart:async';

import 'package:app_bep_xinh/features/fridge/cubits/fridge/fridge_cubit.dart';
import 'package:app_bep_xinh/features/fridge/models/fridge_data.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/fridge/models/fridge_recipe.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_services.dart';

void main() {
  late StubFridgeService service;
  late FridgeCubit cubit;
  setUp(() {
    service = StubFridgeService();
    cubit = FridgeCubit(service: service);
  });
  tearDown(() => cubit.close());

  test(
    'state and suggestions use service response rather than static catalog',
    () async {
      service.onFetch = () async => FridgeData(
        ingredients: const [
          Ingredient(id: 'rice', name: 'Cơm', group: 'Tinh bột'),
        ],
        recipes: const [
          FridgeRecipe(
            id: 'rice_dish',
            title: 'Cơm nóng',
            description: '',
            minutes: 5,
            ingredientIds: ['rice'],
          ),
        ],
        selectedIds: ['rice'],
      );
      expect(cubit.state.ingredients, isEmpty);
      await cubit.loadFridge();
      expect(cubit.state.status, FridgeStatus.success);
      expect(cubit.state.selectedIngredients.single.name, 'Cơm');
      expect(cubit.state.readyRecipes.single.id, 'rice_dish');
      cubit.searchIngredients('com');
      expect(cubit.state.visibleIngredients.single.id, 'rice');
    },
  );

  test('failed initial fetch supports retry and refresh keeps edits', () async {
    service.onFetch = () => Future.error(StateError('offline'));
    await cubit.loadFridge();
    expect(cubit.state.status, FridgeStatus.failure);
    expect(cubit.state.data, isNull);
    service.onFetch = null;
    await cubit.loadFridge();
    await cubit.toggleIngredient('beef');
    final previous = cubit.state.selectedIds;
    service.onFetch = () => Future.error(StateError('offline'));
    await cubit.loadFridge();
    expect(cubit.state.selectedIds, previous);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('queued writes preserve order; latest failure restores last saved inventory', () async {
    await cubit.loadFridge();
    final first = Completer<void>();
    final calls = <List<String>>[];
    service.onSave = (ids) {
      calls.add(ids);
      return calls.length == 1
          ? first.future
          : Future.error(StateError('failed'));
    };
    final one = cubit.toggleIngredient('beef');
    final two = cubit.removeIngredient('egg');
    expect(cubit.state.isSaving, isTrue);
    expect(cubit.state.selectedIds, isNot(contains('egg')));
    await Future<void>.value();
    expect(calls.length, 1);
    first.complete();
    await Future.wait([one, two]);
    expect(calls.length, 2);
    expect(calls.first, contains('egg'));
    expect(calls.last, isNot(contains('egg')));
    expect(cubit.state.selectedIds, calls.first);
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('closed Cubit ignores an in-flight fetch and write', () async {
    final pending = Completer<FridgeData>();
    service.onFetch = () => pending.future;
    final loading = cubit.loadFridge();
    await cubit.close();
    pending.complete(fridgeFixture());
    await expectLater(loading, completes);

    final other = FridgeCubit(service: service);
    service.onFetch = null;
    await other.loadFridge();
    final saved = Completer<void>();
    service.onSave = (_) => saved.future;
    final saving = other.toggleIngredient('beef');
    await other.close();
    saved.complete();
    await expectLater(saving, completes);
  });

  test(
    'refresh waits for pending write and keeps an edit made during refresh',
    () async {
      await cubit.loadFridge();
      final write = Completer<void>();
      final reads = Completer<FridgeData>();
      final writes = <List<String>>[];
      var fetchCalls = 0;
      service.onSave = (ids) {
        writes.add(ids);
        return write.future;
      };
      service.onFetch = () {
        fetchCalls++;
        return reads.future;
      };
      final saving = cubit.toggleIngredient('beef');
      final refreshing = cubit.loadFridge();
      expect(identical(refreshing, cubit.loadFridge()), isTrue);
      final removing = cubit.removeIngredient('egg');
      await Future<void>.value();
      expect(fetchCalls, 0);
      write.complete();
      await saving;
      await Future<void>.value();
      expect(fetchCalls, 1);
      reads.complete(fridgeFixture().withInventory(writes.first));
      await Future.wait([refreshing, removing]);
      expect(writes.length, 2);
      expect(cubit.state.selectedIds, contains('beef'));
      expect(cubit.state.selectedIds, isNot(contains('egg')));
      expect(cubit.state.isSaving, isFalse);
    },
  );
}
