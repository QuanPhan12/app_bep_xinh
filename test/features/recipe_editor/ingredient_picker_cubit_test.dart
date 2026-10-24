import 'dart:async';

import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/cubits/ingredient_picker/ingredient_picker_cubit.dart';
import 'package:app_bep_xinh/features/recipe_editor/cubits/recipe_editor/recipe_editor_cubit.dart';
import 'package:app_bep_xinh/features/recipe_editor/models/recipe_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_services.dart';
import '../../support/recipe_editor_fakes.dart';

class StubCatalogService implements IngredientCatalogService {
  int fetchCalls = 0;
  Future<IngredientCatalog> Function()? onFetch;
  Future<List<Ingredient>> Function(String)? onSearch;
  @override
  Future<IngredientCatalog> fetchCatalog() {
    fetchCalls++;
    return onFetch?.call() ?? Future.value(catalogFixture());
  }

  @override
  Future<List<Ingredient>> search(String query) =>
      onSearch?.call(query) ??
      Future.value(
        catalogFixture().ingredients
            .where((item) => item.matches(query))
            .toList(),
      );
}

void main() {
  test(
    'catalog load deduplicates, retries and restores the structured row',
    () async {
      final service = StubCatalogService();
      final loading = Completer<IngredientCatalog>();
      service.onFetch = () => loading.future;
      final cubit = IngredientPickerCubit(
        service: service,
        initial: validRecipeDraft().ingredients.single,
      );
      addTearDown(cubit.close);
      final task = cubit.load();
      expect(identical(task, cubit.load()), isTrue);
      expect(service.fetchCalls, 1);
      loading.completeError(StateError('offline'));
      await task;
      expect(cubit.state.failure, isNotNull);
      service.onFetch = null;
      await cubit.load();
      expect(cubit.state.selected!.id, 'egg');
      expect(
        cubit.confirm()!.toJson(),
        validRecipeDraft().ingredients.single.toJson(),
      );
    },
  );

  test('decimal amount, allowed units, validation and to taste produce typed payload', () async {
    final cubit = IngredientPickerCubit(service: StubCatalogService());
    addTearDown(cubit.close);
    await cubit.load();
    cubit.choose(cubit.state.catalog!.byId['beef']!);
    expect(cubit.confirm(), isNull);
    expect(cubit.state.errors['amount'], isNotNull);
    cubit.changeAmount('0');
    expect(cubit.confirm(), isNull);
    cubit.changeAmount('0,5');
    expect(cubit.state.errors, isEmpty);
    cubit.selectUnit(const IngredientUnit(id: 'ml', label: 'ml'));
    expect(cubit.state.unit!.id, 'g');
    cubit.selectUnit(cubit.state.catalog!.unitsById['kg']!);
    cubit.changeNote('  thái mỏng  ');
    expect(cubit.confirm()!.toJson(), {
      'ingredientId': 'beef',
      'name': 'Thịt bò',
      'amount': .5,
      'unitId': 'kg',
      'toTaste': false,
      'note': 'thái mỏng',
    });
    cubit.changeAmount('1,2,3');
    expect(cubit.confirm(), isNull);
    cubit.setToTaste(true);
    final result = cubit.confirm()!;
    expect(result.amount, isNull);
    expect(result.unitId, isNull);
    expect(result.quantityLabel, 'Vừa đủ');
    cubit.setToTaste(false);
    expect(cubit.confirm(), isNull);
  });

  testWidgets('search debounces typing and ignores out of order responses', (
    tester,
  ) async {
    final service = StubCatalogService();
    final pending = <String, Completer<List<Ingredient>>>{};
    service.onSearch = (query) => (pending[query] = Completer()).future;
    final cubit = IngredientPickerCubit(
      service: service,
      debounce: const Duration(milliseconds: 30),
    );
    addTearDown(cubit.close);
    await cubit.load();
    cubit.search('t');
    cubit.search('trung');
    await tester.pump(const Duration(milliseconds: 31));
    expect(pending.keys, ['trung']);
    cubit.search('bo');
    await tester.pump(const Duration(milliseconds: 31));
    pending['bo']!.complete([catalogFixture().byId['beef']!]);
    await tester.pump();
    pending['trung']!.complete([catalogFixture().byId['egg']!]);
    await tester.pump();
    expect(cubit.state.results.single.id, 'beef');
    expect(cubit.state.searching, isFalse);
  });

  testWidgets(
    'failed search retries and pending search is canceled safely on close',
    (tester) async {
      final service = StubCatalogService();
      service.onSearch = (_) => Future.error(StateError('offline'));
      final cubit = IngredientPickerCubit(
        service: service,
        debounce: const Duration(milliseconds: 30),
      );
      await cubit.load();
      cubit.search('trung');
      await tester.pump(const Duration(milliseconds: 31));
      expect(cubit.state.failure, isNotNull);
      cubit.chooseCustom();
      expect(cubit.state.hasSelection, isFalse);
      service.onSearch = null;
      cubit.search('trung');
      await tester.pump(const Duration(milliseconds: 31));
      expect(cubit.state.results.single.id, 'egg');
      expect(cubit.state.failure, isNull);
      final pending = Completer<List<Ingredient>>();
      service.onSearch = (_) => pending.future;
      cubit.search('bo');
      await tester.pump(const Duration(milliseconds: 31));
      await cubit.close();
      pending.complete([]);
      await tester.pump(const Duration(milliseconds: 31));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'exact aliases resolve to catalog, unknown ingredient remains custom',
    (tester) async {
      final cubit = IngredientPickerCubit(
        service: StubCatalogService(),
        debounce: const Duration(milliseconds: 30),
      );
      addTearDown(cubit.close);
      await cubit.load();
      cubit.search('dau phu');
      await tester.pump(const Duration(milliseconds: 31));
      cubit.chooseCustom();
      expect(cubit.state.selected!.id, 'tofu');
      cubit.changeSelection();
      cubit.search('Lá mắc mật');
      await tester.pump(const Duration(milliseconds: 31));
      cubit.chooseCustom();
      cubit.setToTaste(true);
      final result = cubit.confirm()!;
      expect(result.ingredientId, isNull);
      expect(result.name, 'Lá mắc mật');
    },
  );

  test('editor rejects duplicate IDs and names; edits preserve identity and removal can empty list', () async {
    final cubit = RecipeEditorCubit(
      service: StubRecipeEditorService(),
      coverPicker: StubRecipeCoverPicker(),
    );
    addTearDown(cubit.close);
    await cubit.loadDraft();
    final item = validRecipeDraft().ingredients.single.withId('');
    cubit.upsertIngredient(item);
    cubit.upsertIngredient(item);
    expect(cubit.state.draft.ingredients.length, 1);
    final id = cubit.state.draft.ingredients.single.id;
    cubit.upsertIngredient(
      const RecipeIngredientDraft(id: '', name: 'trung ga', toTaste: true),
    );
    expect(cubit.state.draft.ingredients.length, 1);
    cubit.upsertIngredient(
      RecipeIngredientDraft(
        id: id,
        ingredientId: 'egg',
        name: 'Trứng gà',
        amount: 3,
        unit: item.unit,
      ),
    );
    expect(cubit.state.draft.ingredients.single.id, id);
    expect(cubit.state.draft.ingredients.single.amount, 3);
    cubit.removeIngredient(id);
    expect(cubit.state.draft.ingredients, isEmpty);
    await cubit.submit();
    expect(cubit.state.errors['ingredients'], isNotNull);
  });
}
