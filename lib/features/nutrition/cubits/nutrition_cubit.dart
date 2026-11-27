import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ai_chat/models/ai_message.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../meal_planner/services/meal_ingredients.dart';
import '../../recipe_detail/models/recipe_detail.dart';
import '../models/nutrition.dart';
import '../services/nutrition_repository.dart';
import '../services/nutrition_photo_picker.dart';

class NutritionState {
  final NutritionCatalog? catalog;
  final List<NutritionLine> lines;
  final Uint8List? photo;
  final String description, title, day;
  final MealSlot slot;
  final int servings, consumed, tab;
  final bool loading, busy, saved;
  final String? error;
  const NutritionState({
    this.catalog,
    this.lines = const [],
    this.photo,
    this.description = '',
    this.title = 'Bữa ăn của tôi',
    this.day = '',
    this.slot = MealSlot.dinner,
    this.servings = 1,
    this.consumed = 1,
    this.tab = 0,
    this.loading = true,
    this.busy = false,
    this.saved = false,
    this.error,
  });
  NutritionState change({
    NutritionCatalog? catalog,
    List<NutritionLine>? lines,
    Uint8List? photo,
    bool clearPhoto = false,
    String? description,
    String? title,
    String? day,
    MealSlot? slot,
    int? servings,
    int? consumed,
    int? tab,
    bool? loading,
    bool? busy,
    bool? saved,
    String? error,
  }) => NutritionState(
    catalog: catalog ?? this.catalog,
    lines: List.unmodifiable(lines ?? this.lines),
    photo: clearPhoto ? null : photo ?? this.photo,
    description: description ?? this.description,
    title: title ?? this.title,
    day: day ?? this.day,
    slot: slot ?? this.slot,
    servings: servings ?? this.servings,
    consumed: consumed ?? this.consumed,
    tab: tab ?? this.tab,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    saved: saved ?? this.saved,
    error: error,
  );
  bool get ready =>
      lines.isNotEmpty &&
      catalog != null &&
      lines.every((l) => l.confirmed && catalog!.valid(l));
  NutritionTotals? get total => ready ? catalog!.total(lines) : null;
}

class NutritionCubit extends Cubit<NutritionState> {
  final NutritionRepository repository;
  final NutritionPhotoPicker photos;
  final KitchenServices kitchen;
  String _entryId = kitchenId(), _requestId = kitchenId();
  NutritionCubit({
    required this.repository,
    required this.photos,
    required this.kitchen,
  }) : super(NutritionState(day: dateKey(DateTime.now())));
  Future<void> load({String? recipeId, String? mealId, int? servings}) async {
    try {
      final catalog = await repository.catalog();
      if (isClosed) return;
      emit(state.change(catalog: catalog, loading: false));
      if (recipeId != null) {
        final recipe = (await kitchen.details.fetchRecipe(recipeId)).recipe;
        if (!isClosed) {
          useRecipes(
            [recipe],
            title: recipe.title,
            servings: servings ?? recipe.servings,
          );
        }
      } else if (mealId != null) {
        final meal = await kitchen.meals.find(mealId);
        if (meal == null) throw const FormatException('Bữa ăn đã bị xóa.');
        final recipes = await Future.wait(
          meal.dishes.map(
            (d) async =>
                (await kitchen.details.fetchRecipe(d.recipe.id)).recipe,
          ),
        );
        if (!isClosed) {
          useRecipes(recipes, title: meal.displayName, servings: meal.servings);
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          state.change(
            loading: false,
            error: e is FormatException
                ? e.message
                : 'Chưa tải được dữ liệu dinh dưỡng. Hãy thử lại.',
          ),
        );
      }
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (state.busy || isClosed) return false;
    emit(state.change(busy: true));
    try {
      await action();
      if (isClosed) return false;
      emit(state.change(busy: false));
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.change(
            busy: false,
            error: e is AiChatFailure
                ? e.message
                : e is FormatException
                ? e.message
                : 'Chưa thực hiện được. Kiểm tra kết nối và thử lại.',
          ),
        );
      }
      return false;
    }
  }

  void tab(int value) => emit(state.change(tab: value));
  void description(String value) {
    if (state.busy || state.saved) return;
    _requestId = kitchenId();
    emit(state.change(description: value));
  }

  void metadata({
    String? title,
    String? day,
    MealSlot? slot,
    int? servings,
    int? consumed,
  }) {
    if (state.busy || state.saved) return;
    final all = servings ?? state.servings;
    emit(
      state.change(
        title: title,
        day: day,
        slot: slot,
        servings: all,
        consumed: (consumed ?? state.consumed).clamp(1, all),
      ),
    );
  }

  void useRecipes(
    List<RecipeDetail> recipes, {
    required String title,
    required int servings,
  }) {
    if (state.busy || state.saved || state.catalog == null) return;
    final plan = MealPlanEntry(
      id: 'nutrition',
      day: state.day,
      slot: state.slot,
      servings: servings,
      dishes: recipes
          .map((r) => MealDish(recipe: RecipeRef.fromRecipe(r)))
          .toList(),
    );
    final ingredients = MealIngredients.aggregate(plan, {
      for (final r in recipes) r.id: r,
    });
    _requestId = kitchenId();
    emit(
      state.change(
        title: title,
        servings: servings,
        consumed: 1,
        clearPhoto: true,
        description: '',
        lines: [
          for (final line in ingredients)
            NutritionLine(
              id: line.key,
              name: line.name,
              sourceQuantity: line.quantity(),
              foodId: state.catalog!.byIngredient[line.ingredientId]?.id,
              grams:
                  line.unit?.id == 'g' &&
                      !line.toTaste &&
                      line.amount != null &&
                      line.amount! <= 100000
                  ? line.amount!.round().clamp(1, 100000).toDouble()
                  : null,
            ),
        ],
      ),
    );
  }

  Future<bool> choosePhoto({bool camera = false}) => _run(() async {
    final image = await photos.pick(camera: camera);
    if (image != null && !isClosed) {
      _requestId = kitchenId();
      emit(state.change(photo: image, lines: const []));
    }
  });
  void clearPhoto() {
    if (!state.busy && !state.saved) {
      _requestId = kitchenId();
      emit(state.change(clearPhoto: true));
    }
  }

  Future<bool> recognize() => _run(() async {
    if (state.catalog == null) {
      throw const FormatException('Chưa có bảng dinh dưỡng. Hãy tải lại.');
    }
    final input = state.lines;
    final result = <NutritionLine>[];
    if (input.isEmpty) {
      result.addAll(
        await repository.recognize(
          id: _requestId,
          text: state.description,
          catalog: state.catalog!,
          image: state.photo,
        ),
      );
    } else {
      // Mỗi nhóm tối đa 30 nguyên liệu là một lượt AI, cùng hạn mức với Chat.
      for (var start = 0; start < input.length; start += 30) {
        final end = (start + 30).clamp(0, input.length);
        final batchId = start == 0 ? _requestId : _batchId(_requestId, start);
        result.addAll(
          await repository.recognize(
            id: batchId,
            text: state.description,
            catalog: state.catalog!,
            ingredients: input.sublist(start, end),
          ),
        );
        if (isClosed) return;
      }
    }
    if (result.isEmpty) {
      throw const FormatException(
        'Chưa nhận ra thực phẩm. Thử ảnh rõ hơn hoặc nhập món bằng chữ.',
      );
    }
    if (!isClosed) {
      final catalog = await repository.catalog();
      if (isClosed) return;
      _requestId = kitchenId();
      emit(
        state.change(
          catalog: catalog,
          lines: result
              .map(
                (l) => l.grams == null
                    ? l
                    : l.change(
                        grams: l.grams!.round().clamp(1, 100000).toDouble(),
                      ),
              )
              .toList(),
        ),
      );
    }
  });
  String _batchId(String id, int start) =>
      '${id.substring(0, 24)}${start.toRadixString(16).padLeft(8, '0')}';
  void line(
    int index, {
    String? foodId,
    double? grams,
    bool clearGrams = false,
    bool? confirmed,
  }) {
    if (state.busy || state.saved) return;
    final next = [...state.lines];
    next[index] = next[index].change(
      foodId: foodId,
      grams: grams,
      clearGrams: clearGrams,
      confirmed: confirmed,
    );
    _requestId = kitchenId();
    emit(state.change(lines: next));
  }

  void addNamedIngredient(NutritionLine line) {
    if (state.busy || state.saved || state.lines.length >= 180) return;
    _requestId = kitchenId();
    emit(state.change(lines: [...state.lines, line]));
  }

  void addFood(NutritionFood food) {
    if (state.busy || state.saved || state.lines.length >= 180) return;
    _requestId = kitchenId();
    emit(
      state.change(
        lines: [
          ...state.lines,
          NutritionLine(id: kitchenId(), name: food.name, foodId: food.id),
        ],
      ),
    );
  }

  void remove(int index) {
    if (!state.busy && !state.saved) {
      _requestId = kitchenId();
      emit(state.change(lines: [...state.lines]..removeAt(index)));
    }
  }

  void confirmAll() {
    if (state.busy || state.saved) return;
    if (state.lines.any((l) => !state.catalog!.valid(l))) {
      emit(
        state.change(
          error: 'Chọn thực phẩm tham chiếu và nhập gram cho từng dòng trước.',
        ),
      );
      return;
    }
    emit(
      state.change(
        lines: state.lines.map((l) => l.change(confirmed: true)).toList(),
      ),
    );
  }

  Future<bool> save() => _run(() async {
    if (state.saved) return;
    if (!state.ready) {
      throw const FormatException(
        'Kiểm tra và xác nhận toàn bộ nguyên liệu trước khi lưu.',
      );
    }
    final entry = NutritionEntry(
      id: _entryId,
      title: state.title,
      day: state.day,
      slot: state.slot,
      servings: state.servings,
      consumedServings: state.consumed,
      catalogVersion: state.catalog!.version,
      lines: state.lines,
      totals: state.total!.scaled(state.consumed / state.servings),
    );
    entry.toJson();
    await repository.journal.createIfAbsent(entry);
    if (!isClosed) emit(state.change(saved: true));
  });
  void reset() {
    if (state.busy) return;
    _entryId = kitchenId();
    _requestId = kitchenId();
    emit(
      NutritionState(
        catalog: state.catalog,
        loading: false,
        day: dateKey(DateTime.now()),
      ),
    );
  }
}
