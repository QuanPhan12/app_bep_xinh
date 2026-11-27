import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../recipe_detail/models/recipe_detail.dart';
import '../models/meal_session.dart';
import '../services/meal_ingredients.dart';

class MealState {
  final MealPlanEntry? meal;
  final MealSession? session;
  final Map<String, RecipeDetail> recipes;
  final List<MealIngredient> ingredients;
  final List<PantryLot> pantry;
  final Set<String> fridgeIds;
  final bool loading, busy;
  final String? error;
  final int tab;
  const MealState({
    this.meal,
    this.session,
    this.recipes = const {},
    this.ingredients = const [],
    this.pantry = const [],
    this.fridgeIds = const {},
    this.loading = true,
    this.busy = false,
    this.error,
    this.tab = 0,
  });
  MealState change({
    MealPlanEntry? meal,
    MealSession? session,
    bool? busy,
    String? error,
    int? tab,
  }) => MealState(
    meal: meal ?? this.meal,
    session: session ?? this.session,
    recipes: recipes,
    ingredients: ingredients,
    pantry: pantry,
    fridgeIds: fridgeIds,
    loading: false,
    busy: busy ?? this.busy,
    error: error,
    tab: tab ?? this.tab,
  );
}

class MealCubit extends Cubit<MealState> {
  final KitchenServices services;
  final String id;
  StreamSubscription<List<MealSession>>? _sessions;
  MealCubit(this.services, this.id) : super(const MealState());
  Future<void> load() async {
    MealPlanEntry? loadedMeal;
    MealSession? loadedSession;
    try {
      final meal = await services.meals.find(id);
      loadedMeal = meal;
      if (meal == null) throw const FormatException('Bữa ăn đã bị xóa.');
      final session = await services.mealSessions.find(id);
      loadedSession = session;
      final plan = session?.plan ?? meal;
      final recipes = <String, RecipeDetail>{};
      await Future.wait(
        plan.dishes.map((dish) async {
          recipes[dish.recipe.id] = (await services.details.fetchRecipe(
            dish.recipe.id,
          )).recipe;
        }),
      );
      final pantry = await services.pantry.fetch();
      final fridge = await services.fridge.fetchFridge();
      if (isClosed) return;
      emit(
        MealState(
          meal: meal,
          session: session,
          recipes: Map.unmodifiable(recipes),
          ingredients: MealIngredients.aggregate(plan, recipes),
          pantry: pantry,
          fridgeIds: fridge.selectedIds.toSet(),
          loading: false,
          tab: state.tab,
        ),
      );
      await _sessions?.cancel();
      _sessions = services.mealSessions.watch().listen(
        (items) {
          final found = items.where((s) => s.id == id).firstOrNull;
          if (!isClosed && found != null) emit(state.change(session: found));
        },
        onError: (Object _, StackTrace _) {
          if (!isClosed) {
            emit(
              state.change(
                error:
                    'Không đồng bộ được tiến độ. Kiểm tra kết nối và tải lại.',
              ),
            );
          }
        },
      );
    } catch (error) {
      if (!isClosed) {
        emit(
          MealState(
            meal: loadedMeal,
            session: loadedSession,
            loading: false,
            error: error is FormatException ? error.message : 'Chưa tải được bữa ăn. Một món có thể đã bị ẩn hoặc mất kết nối.',
          ),
        );
      }
    }
  }

  void selectTab(int tab) => emit(state.change(tab: tab));
  Future<bool> run(Future<void> Function() action) async {
    if (state.busy || isClosed) return false;
    emit(state.change(busy: true));
    try {
      await action();
      if (isClosed) return false;
      emit(state.change(busy: false));
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          state.change(
            busy: false,
            error: error is FormatException
                ? error.message
                : 'Chưa lưu được thay đổi. Kiểm tra kết nối rồi thử lại.',
          ),
        );
      }
      return false;
    }
  }

  Future<bool> start() => run(() async {
    await services.mealSessions.createIfAbsent(MealSession.start(state.meal!));
    final session = await services.mealSessions.find(id);
    if (!isClosed) emit(state.change(session: session, tab: 2));
  });
  Future<bool> progress({String? selected, int? step, bool? done}) =>
      run(() async {
        await services.mealSessions.update(id, (current) {
          if (current.completed) {
            throw const FormatException('Bữa ăn đã hoàn tất.');
          }
          final recipeId = selected ?? current.selectedRecipeId;
          final steps = {...current.steps};
          final completed = {...current.done};
          if (step != null) {
            final recipe = state.recipes[recipeId]!;
            kitchenInt(step, 0, recipe.steps.length - 1);
            steps[recipeId] = step;
          }
          if (done == true) completed.add(recipeId);
          if (done == false) completed.remove(recipeId);
          return current.copyWith(
            selectedRecipeId: recipeId,
            steps: steps,
            done: completed.toList(),
          );
        });
      });
  Future<bool> prepared(String key, bool value) => run(() async {
    await services.meals.update(id, (current) {
      final keys = {...current.preparedKeys};
      value ? keys.add(key) : keys.remove(key);
      return current.copyWith(preparedKeys: keys.toList());
    });
    final meal = await services.meals.find(id);
    if (!isClosed) emit(state.change(meal: meal));
  });
  List<ShoppingLine> get missing => MealIngredients.missing(
    state.meal!,
    state.ingredients,
    state.pantry,
    DateTime.now(),
  );
  Future<bool> addShopping() => run(() async {
    // Tải lại kho trước khi tổng hợp để giỏ không dựa vào lượng đã cũ trên màn hình.
    final pantry = await services.pantry.fetch();
    final meal = (await services.meals.find(id))!;
    final lines = MealIngredients.missing(
      meal,
      state.ingredients,
      pantry,
      DateTime.now(),
    );
    await services.shopping.createIfAbsent(
      ShoppingBatch(id: id, title: meal.displayName, lines: const []),
    );
    await services.shopping.update(id, (current) {
      final checked = {for (final line in current.lines) line.key: line};
      return ShoppingBatch(
        id: id,
        title: meal.displayName,
        lines: [
          for (final line in lines)
            ShoppingLine(
              key: line.key,
              name: line.name,
              quantity: line.quantity,
              checked:
                  checked[line.key]?.displayQuantity == line.displayQuantity &&
                  (checked[line.key]?.checked ?? false),
            ),
        ],
      );
    });
  });
  Future<bool> timer(RecipeDetail recipe, int index) => run(() async {
    final step = recipe.steps[index];
    if (step.minutes == null || state.session?.completed == true) return;
    final label = '${recipe.title} · Bước ${index + 1}';
    await services.timers.start(
      label,
      Duration(minutes: step.minutes!),
      id: mealKey('$id/${recipe.id}/${step.id}'),
      groupId: id,
    );
  });
  Future<bool> complete() => run(() async {
    await services.mealActions.complete(id);
    final session = await services.mealSessions.find(id);
    if (!isClosed) emit(state.change(session: session));
    await services.timers.removeGroup(id);
  });
  Future<bool> consume(List<PantryDeduction> deductions) => run(() async {
    await services.mealActions.consume(id, deductions);
    await load();
  });
  Future<List<PantryDeduction>> previewConsumption() async =>
      MealIngredients.deductions(
        state.ingredients,
        await services.pantry.fetch(),
        DateTime.now(),
      );
  Future<bool> delete() => run(() => services.meals.delete(id));
  @override
  Future<void> close() async {
    await _sessions?.cancel();
    return super.close();
  }
}
