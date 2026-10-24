import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/utils/search_utils.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';

import 'ingredient_picker_state.dart';
import '../../models/recipe_draft.dart';
import '../../validation/recipe_editor_validation.dart';

export 'ingredient_picker_state.dart';

class IngredientPickerCubit extends Cubit<IngredientPickerState> {
  final IngredientCatalogService service;
  final RecipeIngredientDraft? initial;
  final Duration debounce;
  Timer? _timer;
  int _request = 0;
  Future<void>? _loadTask;

  IngredientPickerCubit({
    required this.service,
    this.initial,
    this.debounce = const Duration(milliseconds: 300),
  }) : super(const IngredientPickerState());

  Future<void> load() =>
      _loadTask ??= _load().whenComplete(() => _loadTask = null);

  Future<void> _load() async {
    if (isClosed) return;
    emit(state.copyWith(loading: true));
    try {
      final catalog = await service.fetchCatalog();
      if (isClosed) return;
      final item = initial;
      final selected = catalog.byId[item?.ingredientId];
      final savedUnit = catalog.unitsById[item?.unitId];
      final allowedUnits = selected?.unitIds ?? catalog.unitsById.keys.toList();
      final unit = savedUnit != null && allowedUnits.contains(savedUnit.id)
          ? savedUnit
          : catalog.unitsById[allowedUnits.first];
      emit(
        state.copyWith(
          catalog: catalog,
          results: catalog.ingredients,
          loading: false,
          selected: selected,
          customName: item != null && catalog.byId[item.ingredientId] == null
              ? item.name
              : null,
          amount: item?.amount?.toString().replaceAll('.', ',') ?? '',
          unit: unit,
          toTaste: item?.toTaste ?? false,
          note: item?.note ?? '',
        ),
      );
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          state.copyWith(
            loading: false,
            failure: 'Không tải được nguyên liệu. Vui lòng thử lại.',
          ),
        );
      }
    }
  }

  void search(String query) {
    if (isClosed || state.catalog == null) return;
    _timer?.cancel();
    final request = ++_request;
    emit(state.copyWith(query: query, searching: true, results: const []));
    _timer = Timer(debounce, () => _search(query, request));
  }

  Future<void> _search(String query, int request) async {
    try {
      final results = await service.search(query.trim());
      if (!isClosed && request == _request) {
        emit(
          state.copyWith(results: List.unmodifiable(results), searching: false),
        );
      }
    } catch (error, stack) {
      if (!isClosed && request == _request) {
        addError(error, stack);
        emit(
          state.copyWith(
            searching: false,
            failure: 'Không tìm được nguyên liệu. Vui lòng thử lại.',
          ),
        );
      }
    }
  }

  void choose(Ingredient ingredient) {
    final known = state.catalog?.byId[ingredient.id];
    if (isClosed || known == null) return;
    _timer?.cancel();
    _request++;
    emit(
      state.copyWith(
        clearSelection: true,
        errors: const {},
        selected: known,
        amount: '',
        note: '',
        toTaste: false,
        unit: state.catalog!.unitsById[known.unitIds.first],
        searching: false,
      ),
    );
  }

  void chooseCustom() {
    if (isClosed ||
        state.catalog == null ||
        state.searching ||
        state.failure != null) {
      return;
    }
    final name = state.query.trim();
    if (name.isEmpty) return;
    final exact = state.catalog!.ingredients
        .where(
          (item) => [
            item.name,
            ...item.aliases,
          ].any((alias) => searchKey(alias) == searchKey(name)),
        )
        .firstOrNull;
    if (exact != null) return choose(exact);
    emit(
      state.copyWith(
        clearSelection: true,
        errors: const {},
        customName: name,
        amount: '',
        note: '',
        toTaste: false,
        unit: state.catalog!.units.first,
      ),
    );
  }

  void changeSelection() {
    if (isClosed) return;
    emit(state.copyWith(clearSelection: true, errors: const {}));
  }

  void changeAmount(String value) => _edit(state.copyWith(amount: value));
  void changeNote(String value) => _edit(state.copyWith(note: value));
  void setToTaste(bool value) => _edit(state.copyWith(toTaste: value));
  void selectUnit(IngredientUnit unit) {
    if (state.availableUnits.contains(unit)) _edit(state.copyWith(unit: unit));
  }

  void _edit(IngredientPickerState next) {
    if (isClosed) return;
    emit(
      next.copyWith(errors: state.errors.isEmpty ? const {} : _errors(next)),
    );
  }

  RecipeIngredientDraft _value(IngredientPickerState value) =>
      RecipeIngredientDraft(
        id: initial?.id ?? '',
        ingredientId: value.selected?.id,
        name: value.name,
        amount: double.tryParse(value.amount.trim().replaceAll(',', '.')),
        unit: value.unit,
        toTaste: value.toTaste,
        note: value.note.trim(),
      ).normalized();

  Map<String, String> _errors(IngredientPickerState value) =>
      RecipeEditorValidation.validateIngredient(_value(value));

  RecipeIngredientDraft? confirm() {
    if (isClosed || !state.hasSelection) return null;
    final errors = _errors(state);
    emit(state.copyWith(errors: errors));
    return errors.isEmpty ? _value(state) : null;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _request++;
    return super.close();
  }
}
