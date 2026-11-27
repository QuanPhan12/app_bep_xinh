import 'package:app_bep_xinh/core/services/firestore_user_store.dart';
import 'package:app_bep_xinh/features/kitchen/models/kitchen_entry.dart';
import 'package:app_bep_xinh/features/kitchen/services/kitchen_repository.dart';
import 'package:app_bep_xinh/features/meal_planner/models/meal_session.dart';
import 'package:app_bep_xinh/features/meal_planner/services/meal_actions_repository.dart';
import 'package:app_bep_xinh/features/meal_planner/services/meal_ingredients.dart';

Future<void> mealSdkSmoke(FirestoreUserStore store) async {
  void check(bool condition, String message) {
    if (!condition) throw StateError(message);
  }

  final meals = FirestoreKitchenRepository(
    store: store,
    collection: 'meal_plans',
    decode: MealPlanEntry.fromJson,
  );
  final sessions = FirestoreKitchenRepository(
    store: store,
    collection: 'meal_sessions',
    decode: MealSession.fromJson,
  );
  final pantry = FirestoreKitchenRepository(
    store: store,
    collection: 'pantry_lots',
    decode: PantryLot.fromJson,
  );
  final shopping = FirestoreKitchenRepository(
    store: store,
    collection: 'shopping_batches',
    decode: ShoppingBatch.fromJson,
  );
  final journal = FirestoreKitchenRepository(
    store: store,
    collection: 'cooking_logs',
    decode: CookingLog.fromJson,
  );
  const meal = MealPlanEntry(
    id: 'sdk-meal',
    name: 'Bữa SDK',
    day: '2026-11-27',
    slot: MealSlot.dinner,
    servings: 4,
    dishes: [
      MealDish(
        recipe: RecipeRef(id: 'tofu_tomato', title: 'Đậu sốt cà', authorId: ''),
        role: MealDishRole.main,
      ),
      MealDish(
        recipe: RecipeRef(id: 'bo_ne_tieu_den', title: 'Bò né', authorId: ''),
        role: MealDishRole.soup,
      ),
    ],
  );
  await meals.save(meal);
  await sessions.createIfAbsent(MealSession.start(meal));
  await sessions.update(
    meal.id,
    (s) => s.copyWith(
      selectedRecipeId: 'bo_ne_tieu_den',
      steps: {'tofu_tomato': 1, 'bo_ne_tieu_den': 2},
    ),
  );
  await sessions.createIfAbsent(MealSession.start(meal));
  check(
    (await sessions.find(meal.id))!.steps['bo_ne_tieu_den'] == 2,
    'start retry preserves steps',
  );
  final actions = FirestoreMealActionsRepository(store);
  var rejected = false;
  try {
    await actions.complete(meal.id);
  } catch (_) {
    rejected = true;
  }
  check(rejected, 'incomplete meal cannot complete');
  await sessions.update(
    meal.id,
    (s) => s.copyWith(done: meal.dishes.map((d) => d.recipe.id).toList()),
  );
  await Future.wait([actions.complete(meal.id), actions.complete(meal.id)]);
  check(
    (await journal.fetch())
            .where((l) => l.note == 'Nấu trong bữa: Bữa SDK')
            .length ==
        2,
    'completion retry creates two logs only',
  );
  check((await sessions.find(meal.id))!.completed, 'completed persists');
  const lot = PantryLot(
    id: 'sdk-lot',
    ingredientId: 'tofu',
    name: 'Đậu hũ',
    amount: 10,
    unitId: 'g',
  );
  await pantry.save(lot);
  await Future.wait([
    actions.consume(meal.id, [const PantryDeduction(lot, 3)]),
    actions.consume(meal.id, [const PantryDeduction(lot, 3)]),
  ]);
  check(
    (await pantry.find(lot.id))!.amount == 7,
    'concurrent retry deducts pantry once',
  );
  const other = MealPlanEntry(
    id: 'sdk-stale',
    name: 'Kho đổi',
    day: '2026-11-27',
    slot: MealSlot.lunch,
    servings: 2,
    recipe: RecipeRef(id: 'tofu_tomato', title: 'Đậu', authorId: ''),
  );
  await meals.save(other);
  await sessions.createIfAbsent(MealSession.start(other));
  await sessions.update(other.id, (s) => s.copyWith(done: ['tofu_tomato']));
  await actions.complete(other.id);
  rejected = false;
  try {
    await actions.consume(other.id, [const PantryDeduction(lot, 3)]);
  } catch (_) {
    rejected = true;
  }
  check(
    rejected &&
        (await pantry.find(lot.id))!.amount == 7 &&
        !(await sessions.find(other.id))!.pantryConsumed,
    'stale preview rolls back whole transaction',
  );
  await shopping.save(
    const ShoppingBatch(
      id: 'sdk-meal',
      title: 'Bữa SDK',
      lines: [ShoppingLine(key: 'tofu', name: 'Đậu', quantity: '2 g')],
    ),
  );
  await shopping.update(
    'sdk-meal',
    (batch) => ShoppingBatch(
      id: batch.id,
      title: batch.title,
      lines: [batch.lines.single.toggle()],
    ),
  );
  check(
    (await shopping.find('sdk-meal'))!.lines.single.checked,
    'shopping check persists',
  );
  final legacy = (await meals.find(other.id))!;
  check(legacy.dishes.length == 1, 'legacy meal readable');
  await meals.update(other.id, (m) => m.copyWith(preparedKeys: ['ready']));
  check(
    (await meals.find(other.id))!.preparedKeys.single == 'ready',
    'legacy upgrade after start',
  );
}
