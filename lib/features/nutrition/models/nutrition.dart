import 'dart:convert';

import '../../kitchen/models/kitchen_entry.dart';

class NutritionFood {
  final String id, name, description;
  final String? ingredientId;
  final double kcal, protein, carbs, fat;
  const NutritionFood({
    required this.id,
    required this.name,
    required this.description,
    this.ingredientId,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
  factory NutritionFood.fromJson(Map<String, dynamic> json) => NutritionFood(
    id: '${json['id']}',
    name: json['name'] as String,
    description: json['description'] as String,
    ingredientId: json['ingredientId'] as String?,
    kcal: (json['kcal'] as num).toDouble(),
    protein: (json['protein'] as num).toDouble(),
    carbs: (json['carbs'] as num).toDouble(),
    fat: (json['fat'] as num).toDouble(),
  );
  Map<String, dynamic> get prompt => {
    'id': id,
    'name': name,
    'description': description,
  };
}

class NutritionLine {
  final String id, name;
  final String? foodId;
  final String? sourceQuantity;
  final double? grams;
  final bool confirmed;
  const NutritionLine({
    required this.id,
    required this.name,
    this.foodId,
    this.sourceQuantity,
    this.grams,
    this.confirmed = false,
  });
  NutritionLine change({
    String? foodId,
    double? grams,
    bool clearGrams = false,
    bool? confirmed,
  }) => NutritionLine(
    id: id,
    name: name,
    foodId: foodId ?? this.foodId,
    sourceQuantity: sourceQuantity,
    grams: clearGrams ? null : grams ?? this.grams,
    confirmed: confirmed ?? false,
  );
  Map<String, dynamic> toJson() => {
    'id': kitchenKey(id),
    'name': kitchenText(name, 80),
    if (sourceQuantity != null)
      'sourceQuantity': kitchenText(sourceQuantity, 100, empty: true),
    'foodId': foodId,
    'grams': grams,
    'confirmed': confirmed,
  };
  factory NutritionLine.fromJson(Map<String, dynamic> json) => NutritionLine(
    id: kitchenKey(json['id']),
    name: kitchenText(json['name'], 80),
    foodId: json['foodId'] as String?,
    sourceQuantity: json['sourceQuantity'] == null
        ? null
        : kitchenText(json['sourceQuantity'], 100, empty: true),
    grams: (json['grams'] as num?)?.toDouble(),
    confirmed: json['confirmed'] == true,
  );
}

class NutritionTotals {
  final double kcal, protein, carbs, fat;
  const NutritionTotals(this.kcal, this.protein, this.carbs, this.fat);
  NutritionTotals scaled(double ratio) => NutritionTotals(
    kcal * ratio,
    protein * ratio,
    carbs * ratio,
    fat * ratio,
  );
  Map<String, dynamic> toJson() => {
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };
  factory NutritionTotals.fromJson(Map<String, dynamic> json) {
    double value(String key) {
      final v = (json[key] as num).toDouble();
      if (!v.isFinite || v < 0 || v > 10000000) {
        throw const FormatException('Dữ liệu dinh dưỡng không hợp lệ.');
      }
      return v;
    }

    return NutritionTotals(
      value('kcal'),
      value('protein'),
      value('carbs'),
      value('fat'),
    );
  }
}

class NutritionCatalog {
  final String version, source;
  final List<NutritionFood> foods;
  final List<String> ingredientNames;
  late final Map<String, NutritionFood> byId = {
    for (final food in foods) food.id: food,
  };
  late final Map<String, NutritionFood> byIngredient = {
    for (final food in foods)
      if (food.ingredientId != null) food.ingredientId!: food,
  };
  NutritionCatalog({
    required this.version,
    required this.source,
    required this.foods,
    this.ingredientNames = const [],
  });
  factory NutritionCatalog.fromJson(Map<String, dynamic> json) =>
      NutritionCatalog(
        version: json['version'] as String,
        source: json['source'] as String,
        foods: (json['foods'] as List)
            .map(
              (e) =>
                  NutritionFood.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      );
  List<NutritionFood> get aiFoods =>
      foods.where((f) => f.ingredientId != null).toList();
  bool valid(NutritionLine line) =>
      line.foodId != null &&
      byId.containsKey(line.foodId) &&
      line.grams != null &&
      line.grams!.isFinite &&
      line.grams! > 0 &&
      line.grams! <= 100000;
  NutritionTotals total(List<NutritionLine> lines) {
    var kcal = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0;
    for (final line in lines) {
      if (!valid(line) || !line.confirmed) {
        throw const FormatException(
          'Xác nhận thực phẩm tham chiếu và khối lượng của tất cả nguyên liệu.',
        );
      }
      final food = byId[line.foodId]!, ratio = line.grams! / 100;
      kcal += food.kcal * ratio;
      protein += food.protein * ratio;
      carbs += food.carbs * ratio;
      fat += food.fat * ratio;
    }
    return NutritionTotals(kcal, protein, carbs, fat);
  }
}

class NutritionEntry implements KitchenEntry {
  @override
  final String id;
  final String title, day;
  final MealSlot slot;
  final int servings, consumedServings;
  final String catalogVersion;
  final List<NutritionLine> lines;
  final NutritionTotals totals;
  const NutritionEntry({
    required this.id,
    required this.title,
    required this.day,
    required this.slot,
    required this.servings,
    required this.consumedServings,
    required this.catalogVersion,
    required this.lines,
    required this.totals,
  });
  factory NutritionEntry.fromJson(String id, Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(
      jsonDecode(json['bodyJson'] as String) as Map,
    );
    return NutritionEntry(
      id: id,
      title: kitchenText(json['title'], 80),
      day: dateKey(kitchenDate(json['day'] as String)),
      slot: MealSlot.values.byName(json['slot'] as String),
      servings: kitchenInt(data['servings'], 1, 50),
      consumedServings: kitchenInt(data['consumedServings'], 1, 50),
      catalogVersion: kitchenText(data['catalogVersion'], 80),
      lines: (data['lines'] as List)
          .map(
            (e) => NutritionLine.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      totals: NutritionTotals.fromJson(
        Map<String, dynamic>.from(data['totals'] as Map),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson() {
    kitchenInt(servings, 1, 50);
    kitchenInt(consumedServings, 1, servings);
    if (lines.isEmpty ||
        lines.length > 180 ||
        lines.any(
          (l) =>
              !l.confirmed ||
              l.foodId == null ||
              l.grams == null ||
              !l.grams!.isFinite ||
              l.grams! <= 0 ||
              l.grams! > 100000,
        )) {
      throw const FormatException('Nguyên liệu chưa được xác nhận.');
    }
    NutritionTotals.fromJson(totals.toJson());
    final body = jsonEncode({
      'servings': servings,
      'consumedServings': consumedServings,
      'catalogVersion': catalogVersion,
      'lines': lines.map((l) => l.toJson()).toList(),
      'totals': totals.toJson(),
    });
    if (utf8.encode(body).length > 100000) {
      throw const FormatException('Bữa ăn có quá nhiều dữ liệu.');
    }
    return {
      'title': kitchenText(title, 80),
      'day': dateKey(kitchenDate(day)),
      'slot': slot.name,
      'bodyJson': body,
    };
  }
}
