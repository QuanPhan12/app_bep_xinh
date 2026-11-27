import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/core/themes/app_theme.dart';
import 'package:app_bep_xinh/features/kitchen/models/kitchen_entry.dart';
import 'package:app_bep_xinh/features/kitchen/services/kitchen_services.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/meal_planner/models/meal_session.dart';
import 'package:app_bep_xinh/features/meal_planner/services/meal_ingredients.dart';
import 'package:app_bep_xinh/features/meal_planner/cubits/meal_cubit.dart';
import 'package:app_bep_xinh/features/meal_planner/cubits/meal_editor_cubit.dart';
import 'package:app_bep_xinh/features/meal_planner/screens/meal_detail_screen.dart';
import 'package:app_bep_xinh/features/meal_planner/screens/meal_editor_screen.dart';
import 'package:app_bep_xinh/features/cart/screens/cart_screen.dart';
import 'package:app_bep_xinh/features/recipe_detail/models/recipe_detail.dart';

import '../support/kitchen_fakes.dart';
import '../support/recipe_detail_fakes.dart';
import '../support/test_text_styles.dart';

const g = IngredientUnit(id: 'g', label: 'g'),
    kg = IngredientUnit(id: 'kg', label: 'kg');
RecipeDetail recipe(
  String id,
  List<RecipeIngredient> ingredients, {
  int servings = 2,
}) {
  final base = detailFixture();
  return RecipeDetail(
    id: id,
    author: base.author,
    content: RecipeContent(
      title: 'Món $id',
      preparationMinutes: 5,
      cookingMinutes: 10,
      servings: servings,
      difficulty: base.difficulty,
      ingredientGroups: base.ingredientGroups,
      ingredients: ingredients,
      steps: base.steps,
    ),
  );
}

MealPlanEntry plan(List<RecipeDetail> recipes) => MealPlanEntry(
  id: 'meal',
  name: 'Bữa tối gia đình',
  day: dateKey(DateTime.now()),
  slot: MealSlot.dinner,
  servings: 4,
  dishes: [for (final r in recipes) MealDish(recipe: RecipeRef.fromRecipe(r))],
);

void main() {
  setUpAll(configureTestTextStyles);
  test('meal scaling displays whole quantities and keeps precise amounts for stock', () {
    final dish = recipe('thirds', [
      const RecipeIngredient(
        id: 'bread',
        ingredientId: 'bread',
        name: 'Bánh mì',
        amount: 5,
        unit: IngredientUnit(id: 'piece', label: 'cái'),
      ),
      const RecipeIngredient(
        id: 'salt',
        ingredientId: 'salt',
        name: 'Muối',
        amount: 100,
        unit: g,
      ),
      const RecipeIngredient(
        id: 'beef',
        ingredientId: 'beef',
        name: 'Thịt bò',
        amount: 500,
        unit: g,
      ),
    ], servings: 3);
    final meal = plan([dish]).copyWith(servings: 2);
    final lines = MealIngredients.aggregate(meal, {dish.id: dish});
    expect(lines.singleWhere((l) => l.name == 'Bánh mì').quantity(), '3 cái');
    expect(lines.singleWhere((l) => l.name == 'Muối').quantity(), '67 g');
    final beef = lines.singleWhere((l) => l.name == 'Thịt bò');
    expect(beef.quantity(), '333 g');
    expect(beef.amount, closeTo(1000 / 3, 1e-10));
    expect(
      const MealIngredient(
        key: 'small',
        name: 'Muối',
        amount: 0.2,
        unit: g,
      ).quantity(),
      '<1 g',
    );
    expect(
      const MealIngredient(
        key: 'taste',
        name: 'Muối',
        toTaste: true,
      ).quantity(),
      'Vừa đủ',
    );
    const old = ShoppingLine(
      key: 'old',
      name: 'Thịt bò',
      quantity: '333,333333333 g',
      checked: true,
    );
    final read = ShoppingLine.fromJson(old.toJson());
    expect(read.displayQuantity, '333 g');
    expect(read.quantity, old.quantity);
    expect(read.checked, true);
    expect(
      const ShoppingLine(
        key: 'kg',
        name: 'Thịt bò',
        quantity: '0,2 kg',
      ).displayQuantity,
      '200 g',
    );
    expect(
      const PantryDeduction(
        PantryLot(
          id: 'lot',
          ingredientId: 'beef',
          name: 'Thịt bò',
          amount: 1,
          unitId: 'kg',
        ),
        0.2,
      ).quantity,
      '200 g',
    );
    expect(
      const ShoppingLine(
        key: 'taste',
        name: 'Muối',
        quantity: 'Vừa đủ',
      ).displayQuantity,
      'Vừa đủ',
    );
  });
  test('legacy reads as a single dish; duplicate or empty meal rejected', () {
    final old = MealPlanEntry.fromJson('old', {
      'day': '2026-11-27',
      'slot': 'dinner',
      'servings': 2,
      'recipe': const RecipeRef(id: 'a', title: 'A', authorId: '').toJson(),
    });
    expect(old.dishes.single.recipe.id, 'a');
    expect(old.schemaVersion, 1);
    expect(old.copyWith().schemaVersion, 2);
    expect(
      () => const MealPlanEntry(
        id: 'empty',
        day: '2026-11-27',
        slot: MealSlot.dinner,
        servings: 2,
      ).toJson(),
      throwsFormatException,
    );
    expect(
      () =>
          old.copyWith(dishes: [old.dishes.single, old.dishes.single]).toJson(),
      throwsFormatException,
    );
  });
  test('shared servings merge kg/g, keep custom names, to-taste and incompatible units separate', () {
    final a = recipe('a', [
      const RecipeIngredient(
        id: 'a',
        ingredientId: 'tofu',
        name: 'Đậu',
        amount: 500,
        unit: g,
      ),
      const RecipeIngredient(
        id: 'salt',
        ingredientId: 'salt',
        name: 'Muối',
        toTaste: true,
      ),
      const RecipeIngredient(id: 'custom', name: 'Hỗn hợp', amount: 1, unit: g),
    ]);
    final b = recipe('b', [
      const RecipeIngredient(
        id: 'b',
        ingredientId: 'tofu',
        name: 'Đậu',
        amount: 1,
        unit: kg,
      ),
      const RecipeIngredient(
        id: 'other',
        ingredientId: 'tofu',
        name: 'Đậu',
        amount: 2,
        unit: IngredientUnit(id: 'piece', label: 'miếng'),
      ),
      const RecipeIngredient(id: 'custom', name: 'Hỗn hợp', amount: 1, unit: g),
    ]);
    final lines = MealIngredients.aggregate(plan([a, b]), {'a': a, 'b': b});
    expect(lines.length, 5);
    expect(
      lines.singleWhere((l) => l.ingredientId == 'tofu' && l.unit == g).amount,
      3000,
    );
    expect(lines.where((l) => l.name == 'Hỗn hợp').length, 2);
    expect(lines.singleWhere((l) => l.toTaste).amount, isNull);
  });
  test('stock excludes expired lots, converts matching units, never assumes fridge presence is enough', () {
    final a = recipe('a', [
      const RecipeIngredient(
        id: 'a',
        ingredientId: 'tofu',
        name: 'Đậu',
        amount: 500,
        unit: g,
      ),
    ]);
    final meal = plan([a]),
        lines = MealIngredients.aggregate(plan([a]), {'a': a});
    final lots = [
      const PantryLot(
        id: 'expired',
        ingredientId: 'tofu',
        name: 'Đậu',
        amount: 99,
        unitId: 'kg',
        expiresOn: '2020-01-01',
      ),
      const PantryLot(
        id: 'kg',
        ingredientId: 'tofu',
        name: 'Đậu',
        amount: 0.2,
        unitId: 'kg',
      ),
      const PantryLot(id: 'unknown', ingredientId: 'tofu', name: 'Đậu'),
      const PantryLot(
        id: 'other',
        ingredientId: 'tofu',
        name: 'Đậu',
        amount: 20,
        unitId: 'piece',
      ),
    ];
    final missing = MealIngredients.missing(meal, lines, lots, DateTime.now());
    expect(missing.single.quantity, '800 g');
    expect(
      MealIngredients.deductions(lines, lots, DateTime.now()).single.amount,
      0.2,
    );
    expect(
      MealIngredients.missing(
        meal.copyWith(preparedKeys: [lines.single.key]),
        lines,
        lots,
        DateTime.now(),
      ),
      isEmpty,
    );
  });
  test('switching dishes and reopening retains steps; timer retry and cart sync deduplicate', () async {
    final services = kitchenFixture();
    addTearDown(() => disposeKitchen(services));
    final first = detailFixture(),
        second = detailFixture('tofu_tomato'),
        meal = plan([first, second]);
    await services.meals.save(meal);
    final cubit = MealCubit(services, meal.id);
    addTearDown(cubit.close);
    await cubit.load();
    expect(await cubit.start(), true);
    expect(await cubit.progress(step: 1), true);
    expect(await cubit.progress(selected: second.id), true);
    expect(cubit.state.session!.steps[first.id], 1);
    final reopened = MealCubit(services, meal.id);
    addTearDown(reopened.close);
    await reopened.load();
    expect(reopened.state.session!.selectedRecipeId, second.id);
    expect(reopened.state.session!.steps[first.id], 1);
    final timerIndex = first.steps.indexWhere((s) => s.minutes != null);
    if (timerIndex >= 0) {
      await cubit.timer(first, timerIndex);
      await cubit.timer(first, timerIndex);
      expect(services.timers.items.length, 1);
    }
    expect(await cubit.addShopping(), true);
    final batch = (await services.shopping.find(meal.id))!;
    expect(batch.lines, isNotEmpty);
    await services.shopping.update(
      meal.id,
      (b) => ShoppingBatch(
        id: b.id,
        title: b.title,
        lines: [b.lines.first.toggle(), ...b.lines.skip(1)],
      ),
    );
    expect(await cubit.addShopping(), true);
    expect(await services.shopping.count(), 1);
    expect((await services.shopping.find(meal.id))!.lines.first.checked, true);
    final editor = MealEditorCubit(services, editId: meal.id);
    addTearDown(editor.close);
    await editor.load();
    expect(editor.state.locked, true);
    final copy = MealEditorCubit(services, copyId: meal.id);
    addTearDown(copy.close);
    await copy.load();
    expect(copy.state.locked, false);
    expect(copy.state.dishes.length, 2);
  });
  test(
    'timer group survives pause/reload and clears only meal timers',
    () async {
      final storage = MemoryKitchenStorage(),
          services = kitchenFixture(storage: storage);
      addTearDown(() => disposeKitchen(services));
      await services.timers.start(
        'Bữa · canh',
        const Duration(minutes: 5),
        id: 'same-step',
        groupId: 'meal',
      );
      await services.timers.start('Món khác', const Duration(minutes: 6));
      await services.timers.toggle('same-step');
      expect(services.timers.items.first.groupId, 'meal');
      await services.timers.removeGroup('meal');
      expect(services.timers.items.single.label, 'Món khác');
    },
  );
  test(
    'unavailable recipe keeps meal references and edit route recoverable',
    () async {
      final details = StubRecipeDetailService()
        ..onFetch = (_) => Future.error(StateError('hidden'));
      final services = kitchenFixture(details: details);
      addTearDown(() => disposeKitchen(services));
      final meal = plan([detailFixture()]);
      await services.meals.save(meal);
      final cubit = MealCubit(services, meal.id);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.meal?.id, meal.id);
      expect(cubit.state.error, isNotNull);
      expect(cubit.state.recipes, isEmpty);
      final editor = MealEditorCubit(services, editId: meal.id);
      addTearDown(editor.close);
      await editor.load();
      expect(editor.state.dishes.single.recipe.id, meal.recipe.id);
      expect(editor.state.locked, false);
    },
  );
  for (final dark in [false, true]) {
    for (final size in [
      const Size(390, 844),
      const Size(844, 390),
      const Size(1024, 768),
    ]) {
      testWidgets(
        'meal/editor/cart fit $size dark=$dark with large text and reachable actions',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final services = kitchenFixture();
          final meal = plan([detailFixture(), detailFixture('tofu_tomato')]);
          await services.meals.save(meal);
          for (final screen in [
            MealDetailScreen(id: meal.id),
            MealEditorScreen(copyId: meal.id),
            const CartScreen(),
          ]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                home: KitchenScope(
                  services: services,
                  child: MediaQuery(
                    data: MediaQueryData(
                      size: size,
                      viewInsets: screen is MealEditorScreen
                          ? const EdgeInsets.only(bottom: 120)
                          : EdgeInsets.zero,
                      textScaler: const TextScaler.linear(2),
                    ),
                    child: screen,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (screen is MealDetailScreen) {
              await tester.tap(find.text('Bắt đầu nấu bữa'));
              await tester.pumpAndSettle();
              expect(find.textContaining('Tiếp tục nấu ·'), findsOneWidget);
              expect(tester.takeException(), isNull);
              await tester.tap(find.text('Nguyên liệu'));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          }
          await disposeKitchen(services);
        },
      );
    }
  }
}
