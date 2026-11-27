import 'package:flutter_bloc/flutter_bloc.dart';

import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../fridge/models/fridge_recipe.dart';

class MealEditorState {
  final List<MealDish> dishes;
  final List<FridgeRecipe> suggestions;
  final MealPlanEntry? initial;
  final bool loading, busy, locked;
  final String? error;
  const MealEditorState({
    this.dishes = const [],
    this.suggestions = const [],
    this.initial,
    this.loading = true,
    this.busy = false,
    this.locked = false,
    this.error,
  });
}

class MealEditorCubit extends Cubit<MealEditorState> {
  final KitchenServices services;
  final String? editId, copyId;
  late final String id = editId ?? kitchenId();
  MealEditorCubit(this.services, {this.editId, this.copyId})
    : super(const MealEditorState());
  Future<void> load() async {
    try {
      final source = editId ?? copyId;
      final initial = source == null ? null : await services.meals.find(source);
      if (source != null && initial == null) {
        throw const FormatException('Không tìm thấy bữa ăn.');
      }
      final locked =
          editId != null && await services.mealSessions.find(editId!) != null;
      var suggestions = <FridgeRecipe>[];
      try {
        final fridge = await services.fridge.fetchFridge();
        suggestions =
            fridge.recipes
                .where((r) => r.ingredientIds.any(fridge.selectedIds.contains))
                .toList()
              ..sort(
                (a, b) => a
                    .missingIngredients(fridge.selectedIds)
                    .length
                    .compareTo(b.missingIngredients(fridge.selectedIds).length),
              );
      } catch (_) {
        /* Gợi ý không cản người dùng tự chọn món khi tủ lạnh chưa tải được. */
      }
      if (!isClosed) {
        emit(
          MealEditorState(
            dishes: initial?.dishes ?? const [],
            initial: initial,
            suggestions: suggestions.take(8).toList(),
            loading: false,
            locked: locked,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          MealEditorState(
            loading: false,
            error: error is FormatException
                ? error.message
                : 'Chưa tải được bữa ăn. Hãy thử lại.',
          ),
        );
      }
    }
  }

  void _set({List<MealDish>? dishes, bool? busy, String? error}) => emit(
    MealEditorState(
      dishes: List.unmodifiable(dishes ?? state.dishes),
      initial: state.initial,
      suggestions: state.suggestions,
      loading: false,
      busy: busy ?? state.busy,
      locked: state.locked,
      error: error,
    ),
  );
  void add(RecipeRef recipe) {
    if (state.busy || state.locked) return;
    if (state.dishes.any((d) => d.recipe.id == recipe.id)) {
      _set(error: 'Món này đã có trong bữa.');
      return;
    }
    if (state.dishes.length >= 6) {
      _set(error: 'Mỗi bữa tối đa 6 món.');
      return;
    }
    _set(
      dishes: [
        ...state.dishes,
        MealDish(recipe: recipe),
      ],
    );
  }

  Future<void> addSuggestion(String id) async {
    if (state.busy || state.locked) return;
    _set(busy: true);
    try {
      final detail = await services.details.fetchRecipe(id);
      if (isClosed) return;
      _set(busy: false);
      add(RecipeRef.fromRecipe(detail.recipe));
    } catch (_) {
      if (!isClosed) {
        _set(busy: false, error: 'Món này chưa khả dụng. Hãy chọn món khác.');
      }
    }
  }

  void remove(int index) => _set(dishes: [...state.dishes]..removeAt(index));
  void role(int index, MealDishRole role) {
    final dishes = [...state.dishes];
    dishes[index] = MealDish(recipe: dishes[index].recipe, role: role);
    _set(dishes: dishes);
  }

  void move(int index, int delta) {
    final dishes = [...state.dishes];
    final item = dishes.removeAt(index);
    dishes.insert(index + delta, item);
    _set(dishes: dishes);
  }

  Future<bool> save({
    required String name,
    required String day,
    required MealSlot slot,
    required String servings,
  }) async {
    if (state.busy || state.locked) return false;
    _set(busy: true);
    try {
      if (state.dishes.isEmpty) {
        throw const FormatException('Thêm ít nhất một món cho bữa ăn.');
      }
      if (editId != null && await services.mealSessions.find(id) != null) {
        throw const FormatException(
          'Bữa đã bắt đầu nấu. Hãy dùng lại để tạo bữa mới.',
        );
      }
      final meal = MealPlanEntry(
        id: id,
        name: name,
        day: day,
        slot: slot,
        servings: kitchenInt(int.tryParse(servings), 1, 50),
        dishes: state.dishes,
      );
      meal.toJson();
      if (editId == null) {
        await services.meals.createIfAbsent(meal);
      } else {
        await services.meals.update(id, (_) => meal);
      }
      if (!isClosed) _set(busy: false);
      return true;
    } catch (error) {
      if (!isClosed) {
        _set(
          busy: false,
          error: error is FormatException
              ? error.message
              : 'Chưa lưu được bữa ăn. Kiểm tra kết nối và thử lại.',
        );
      }
      return false;
    }
  }
}
