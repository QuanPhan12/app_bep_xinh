import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/core/utils/search_utils.dart';

class IngredientCategory extends Equatable {
  final String id;
  final String name;
  final int sortOrder;
  const IngredientCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  factory IngredientCategory.fromJson(Map<String, dynamic> json) =>
      IngredientCategory(
        id: JsonReader(json).string('id'),
        name: JsonReader(json).string('name'),
        sortOrder: JsonReader(json).integer('sortOrder'),
      );

  @override
  List<Object> get props => [id, name, sortOrder];
}

class IngredientUnit extends Equatable {
  final String id;
  final String label;
  final String? type;
  const IngredientUnit({required this.id, required this.label, this.type});

  factory IngredientUnit.fromJson(Map<String, dynamic> json) => IngredientUnit(
    id: JsonReader(json).string('id'),
    label: JsonReader(json).string('label'),
    type: JsonReader(json).optionalString('type'),
  );

  @override
  List<Object?> get props => [id, label, type];
}

class Ingredient extends Equatable {
  final String id;
  final String name;
  final String group;
  final List<String> aliases;
  final List<String> unitIds;
  final String? categoryId;
  final String? defaultUnitId;
  String get preferredUnitId => defaultUnitId ?? unitIds.first;
  const Ingredient({
    required this.id,
    required this.name,
    required this.group,
    this.aliases = const [],
    this.unitIds = const [],
    this.categoryId,
    this.defaultUnitId,
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
    categoryId: JsonReader(json).optionalString('categoryId'),
    defaultUnitId: JsonReader(json).optionalString('defaultUnitId'),
  );

  @override
  List<Object?> get props => [
    id,
    name,
    group,
    aliases,
    unitIds,
    categoryId,
    defaultUnitId,
  ];
}

class IngredientCatalog {
  final List<Ingredient> ingredients;
  final List<IngredientUnit> units;
  final List<IngredientCategory> categories;
  final String? version;
  late final Map<String, IngredientCategory> categoriesById = Map.unmodifiable({
    for (final category in categories) category.id: category,
  });
  late final Map<String, Ingredient> byId = Map.unmodifiable({
    for (final item in ingredients) item.id: item,
  });
  late final Map<String, IngredientUnit> unitsById = Map.unmodifiable({
    for (final unit in units) unit.id: unit,
  });

  IngredientCatalog({
    required List<Ingredient> ingredients,
    required List<IngredientUnit> units,
    List<IngredientCategory> categories = const [],
    this.version,
  }) : ingredients = List.unmodifiable(ingredients),
       units = List.unmodifiable(units),
       categories = List.unmodifiable(categories);

  factory IngredientCatalog.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final versioned = json.containsKey('schemaVersion');
    if (versioned &&
        (json['schemaVersion'] != 1 || json['locale'] != 'vi-VN')) {
      throw const FormatException('Unsupported ingredient catalog schema');
    }
    final categories = versioned
        ? reader.objects('categories').map(IngredientCategory.fromJson).toList()
        : <IngredientCategory>[];
    requireUniqueIds(
      categories.map((item) => item.id),
      'ingredient categories',
    );
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final categoriesById = {
      for (final category in categories) category.id: category,
    };
    final items = reader.objects('ingredients').map((entry) {
      if (!versioned) return Ingredient.fromJson(entry);
      final categoryId = JsonReader(entry).string('categoryId');
      final category = categoriesById[categoryId];
      if (category == null) {
        throw const FormatException('Unknown ingredient category');
      }
      final defaultUnit = JsonReader(entry).string('defaultUnitId');
      final item = Ingredient.fromJson({...entry, 'group': category.name});
      if (!item.unitIds.contains(defaultUnit)) {
        throw const FormatException('Invalid default ingredient unit');
      }
      return item;
    }).toList();
    final units = reader.objects('units').map(IngredientUnit.fromJson).toList();
    requireUniqueIds(items.map((item) => item.id), 'ingredients');
    requireUniqueIds(units.map((unit) => unit.id), 'units');
    final unitIds = units.map((unit) => unit.id).toSet();
    if (units.isEmpty ||
        (versioned && (items.isEmpty || categories.isEmpty)) ||
        items.any((item) => item.unitIds.any((id) => !unitIds.contains(id)))) {
      throw const FormatException('Unknown ingredient unit');
    }
    for (final item in items) {
      requireUniqueIds(item.unitIds, 'ingredient units');
      requireUniqueIds(item.aliases.map(searchKey), 'ingredient aliases');
    }
    if (versioned) {
      for (final unit in units) {
        if (!{'mass', 'volume', 'count', 'kitchen'}.contains(unit.type)) {
          throw const FormatException('Invalid ingredient unit type');
        }
      }
    }
    return IngredientCatalog(
      ingredients: items,
      units: units,
      categories: categories,
      version: versioned ? reader.string('version') : null,
    );
  }
}
