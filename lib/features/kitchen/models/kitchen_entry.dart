import 'dart:math';

import '../../recipe_detail/models/recipe_detail.dart';

String kitchenId() => List.generate(
  16,
  (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();

String kitchenText(Object? value, int max, {bool empty = false}) {
  if (value is! String ||
      value.length > max ||
      (!empty && value.trim().isEmpty) ||
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]').hasMatch(value)) {
    throw const FormatException('Nội dung không hợp lệ.');
  }
  return value.trim();
}

String kitchenKey(Object? value) {
  final key = kitchenText(value, 128);
  if (key.contains('/')) throw const FormatException('Mã không hợp lệ.');
  return key;
}

int kitchenInt(Object? value, int min, int max) {
  if (value is! int || value < min || value > max) {
    throw const FormatException('Số không hợp lệ.');
  }
  return value;
}

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime kitchenDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('Ngày không hợp lệ.');
  }
  final date = DateTime.parse(value);
  if (dateKey(date) != value) throw const FormatException('Ngày không hợp lệ.');
  return date;
}

abstract interface class KitchenEntry {
  String get id;
  Map<String, dynamic> toJson();
}

/// Chỉ là nhãn tham chiếu riêng của người dùng, không tạo bản công khai thứ hai.
class RecipeRef {
  final String id;
  final String title;
  final String authorId;
  const RecipeRef({
    required this.id,
    required this.title,
    required this.authorId,
  });
  factory RecipeRef.fromRecipe(RecipeDetail recipe) => RecipeRef(
    id: recipe.id,
    title: recipe.title,
    authorId: recipe.author.id ?? '',
  );
  factory RecipeRef.fromJson(Map<String, dynamic> json) => RecipeRef(
    id: kitchenKey(json['id']),
    title: kitchenText(json['title'], 80),
    authorId: kitchenText(json['authorId'], 128, empty: true),
  );
  Map<String, dynamic> toJson() => {
    'id': kitchenKey(id),
    'title': kitchenText(title, 80),
    'authorId': kitchenText(authorId, 128, empty: true),
  };
}

enum MealSlot { breakfast, lunch, dinner }

extension MealSlotLabel on MealSlot {
  String get label => switch (this) {
    MealSlot.breakfast => 'Bữa sáng',
    MealSlot.lunch => 'Bữa trưa',
    MealSlot.dinner => 'Bữa tối',
  };
}

class MealPlanEntry implements KitchenEntry {
  @override
  final String id;
  final String day;
  final MealSlot slot;
  final RecipeRef recipe;
  final int servings;
  const MealPlanEntry({
    required this.id,
    required this.day,
    required this.slot,
    required this.recipe,
    required this.servings,
  });
  factory MealPlanEntry.fromJson(String id, Map<String, dynamic> json) =>
      MealPlanEntry(
        id: id,
        day: dateKey(kitchenDate(json['day'] as String)),
        slot: MealSlot.values.byName(json['slot'] as String),
        recipe: RecipeRef.fromJson(
          Map<String, dynamic>.from(json['recipe'] as Map),
        ),
        servings: kitchenInt(json['servings'], 1, 50),
      );
  @override
  Map<String, dynamic> toJson() => {
    'day': dateKey(kitchenDate(day)),
    'slot': slot.name,
    'recipe': recipe.toJson(),
    'servings': kitchenInt(servings, 1, 50),
  };
}

class RecipeCollection implements KitchenEntry {
  @override
  final String id;
  final String name;
  final List<String> recipeIds;
  RecipeCollection({
    required this.id,
    required this.name,
    required List<String> recipeIds,
  }) : recipeIds = List.unmodifiable(recipeIds);
  factory RecipeCollection.fromJson(String id, Map<String, dynamic> json) =>
      RecipeCollection(
        id: id,
        name: kitchenText(json['name'], 60),
        recipeIds: Map<String, dynamic>.from(json['recipeIds'] as Map).keys
            .map(kitchenKey)
            .toList(),
      );
  @override
  Map<String, dynamic> toJson() {
    if (recipeIds.length > 100 ||
        recipeIds.toSet().length != recipeIds.length) {
      throw const FormatException('Mỗi bộ sưu tập tối đa 100 món khác nhau.');
    }
    return {
      'name': kitchenText(name, 60),
      'recipeIds': {for (final id in recipeIds) kitchenKey(id): true},
    };
  }
}

class CookingLog implements KitchenEntry {
  @override
  final String id;
  final RecipeRef recipe;
  final String day;
  final int servings;
  final String note;
  const CookingLog({
    required this.id,
    required this.recipe,
    required this.day,
    required this.servings,
    required this.note,
  });
  factory CookingLog.fromJson(String id, Map<String, dynamic> json) =>
      CookingLog(
        id: id,
        recipe: RecipeRef.fromJson(
          Map<String, dynamic>.from(json['recipe'] as Map),
        ),
        day: dateKey(kitchenDate(json['day'] as String)),
        servings: kitchenInt(json['servings'], 1, 50),
        note: kitchenText(json['note'], 1000, empty: true),
      );
  @override
  Map<String, dynamic> toJson() => {
    'recipe': recipe.toJson(),
    'day': dateKey(kitchenDate(day)),
    'servings': kitchenInt(servings, 1, 50),
    'note': kitchenText(note, 1000, empty: true),
  };
}

class PantryLot implements KitchenEntry {
  @override
  final String id;
  final String ingredientId;
  final String name;
  final double? amount;
  final String? unitId;
  final String? expiresOn;
  const PantryLot({
    required this.id,
    required this.ingredientId,
    required this.name,
    this.amount,
    this.unitId,
    this.expiresOn,
  });
  factory PantryLot.fromJson(String id, Map<String, dynamic> json) => PantryLot(
    id: id,
    ingredientId: kitchenKey(json['ingredientId']),
    name: kitchenText(json['name'], 80),
    amount: (json['amount'] as num?)?.toDouble(),
    unitId: json['unitId'] as String?,
    expiresOn: json['expiresOn'] as String?,
  );
  bool isExpired(DateTime today) =>
      expiresOn != null &&
      kitchenDate(expiresOn!).isBefore(kitchenDate(dateKey(today)));
  bool isSoon(DateTime today) =>
      expiresOn != null &&
      !isExpired(today) &&
      kitchenDate(expiresOn!).difference(kitchenDate(dateKey(today))).inDays <=
          3;
  PantryLot withAmount(double value) => PantryLot(
    id: id,
    ingredientId: ingredientId,
    name: name,
    amount: value,
    unitId: unitId,
    expiresOn: expiresOn,
  );
  @override
  Map<String, dynamic> toJson() {
    if ((amount == null) != (unitId == null) ||
        (amount != null &&
            (!amount!.isFinite || amount! < 0 || amount! > 1000000))) {
      throw const FormatException('Lượng tồn kho không hợp lệ.');
    }
    return {
      'ingredientId': kitchenKey(ingredientId),
      'name': kitchenText(name, 80),
      'amount': amount,
      'unitId': unitId == null ? null : kitchenKey(unitId),
      'expiresOn': expiresOn == null ? null : dateKey(kitchenDate(expiresOn!)),
    };
  }
}

class FollowedAuthor implements KitchenEntry {
  @override
  final String id;
  final String name;
  const FollowedAuthor({required this.id, required this.name});
  factory FollowedAuthor.fromJson(String id, Map<String, dynamic> json) =>
      FollowedAuthor(id: id, name: kitchenText(json['name'], 60));
  @override
  Map<String, dynamic> toJson() => {'name': kitchenText(name, 60)};
}
