import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/core/utils/search_utils.dart';

class IngredientUnit extends Equatable {
  final String id;
  final String label;
  const IngredientUnit({required this.id, required this.label});

  factory IngredientUnit.fromJson(Map<String, dynamic> json) => IngredientUnit(
    id: JsonReader(json).string('id'),
    label: JsonReader(json).string('label'),
  );

  @override
  List<Object> get props => [id, label];
}

class Ingredient extends Equatable {
  final String id;
  final String name;
  final String group;
  final List<String> aliases;
  final List<String> unitIds;
  const Ingredient({
    required this.id,
    required this.name,
    required this.group,
    this.aliases = const [],
    this.unitIds = const [],
  });

  bool matches(String query) {
    final terms = searchKey(query).split(RegExp(r'\s+'));
    final text = searchKey([name, ...aliases].join(' '));
    return terms.every(text.contains);
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
    id: JsonReader(json).string('id'),
    name: JsonReader(json).string('name'),
    group: JsonReader(json).string('group'),
    aliases: JsonReader(json).strings('aliases'),
    unitIds: JsonReader(json).strings('unitIds', allowEmpty: false),
  );

  @override
  List<Object> get props => [id, name, group, aliases, unitIds];
}

class IngredientCatalog {
  final List<Ingredient> ingredients;
  final List<IngredientUnit> units;
  late final Map<String, Ingredient> byId = Map.unmodifiable({
    for (final item in ingredients) item.id: item,
  });
  late final Map<String, IngredientUnit> unitsById = Map.unmodifiable({
    for (final unit in units) unit.id: unit,
  });

  IngredientCatalog({
    required List<Ingredient> ingredients,
    required List<IngredientUnit> units,
  }) : ingredients = List.unmodifiable(ingredients),
       units = List.unmodifiable(units);

  factory IngredientCatalog.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final items = reader
        .objects('ingredients')
        .map(Ingredient.fromJson)
        .toList();
    final units = reader.objects('units').map(IngredientUnit.fromJson).toList();
    requireUniqueIds(items.map((item) => item.id), 'ingredients');
    requireUniqueIds(units.map((unit) => unit.id), 'units');
    final unitIds = units.map((unit) => unit.id).toSet();
    if (units.isEmpty ||
        items.any((item) => item.unitIds.any((id) => !unitIds.contains(id)))) {
      throw const FormatException('Unknown ingredient unit');
    }
    return IngredientCatalog(ingredients: items, units: units);
  }
}
