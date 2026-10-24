import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';

class IngredientPickerState extends Equatable {
  final IngredientCatalog? catalog;
  final List<Ingredient> results;
  final String query;
  final bool loading;
  final bool searching;
  final String? failure;
  final Ingredient? selected;
  final String? customName;
  final String amount;
  final IngredientUnit? unit;
  final bool toTaste;
  final String note;
  final Map<String, String> errors;

  const IngredientPickerState({
    this.catalog,
    this.results = const [],
    this.query = '',
    this.loading = true,
    this.searching = false,
    this.failure,
    this.selected,
    this.customName,
    this.amount = '',
    this.unit,
    this.toTaste = false,
    this.note = '',
    this.errors = const {},
  });

  bool get hasSelection => selected != null || customName != null;
  String get name => selected?.name ?? customName ?? '';
  List<IngredientUnit> get availableUnits =>
      catalog?.units
          .where(
            (unit) => selected == null || selected!.unitIds.contains(unit.id),
          )
          .toList() ??
      const [];

  IngredientPickerState copyWith({
    IngredientCatalog? catalog,
    List<Ingredient>? results,
    String? query,
    bool? loading,
    bool? searching,
    String? failure,
    Ingredient? selected,
    String? customName,
    String? amount,
    IngredientUnit? unit,
    bool? toTaste,
    String? note,
    Map<String, String>? errors,
    bool clearSelection = false,
  }) => IngredientPickerState(
    catalog: catalog ?? this.catalog,
    results: results ?? this.results,
    query: query ?? this.query,
    loading: loading ?? this.loading,
    searching: searching ?? this.searching,
    failure: failure,
    selected: clearSelection ? selected : selected ?? this.selected,
    customName: clearSelection ? customName : customName ?? this.customName,
    amount: amount ?? this.amount,
    unit: unit ?? this.unit,
    toTaste: toTaste ?? this.toTaste,
    note: note ?? this.note,
    errors: errors ?? this.errors,
  );

  @override
  List<Object?> get props => [
    catalog,
    results,
    query,
    loading,
    searching,
    failure,
    selected,
    customName,
    amount,
    unit,
    toTaste,
    note,
    errors,
  ];
}
