import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';

class FridgeRecipe extends Equatable {
  final String id;
  final String title;
  final String description;
  final int minutes;
  final bool isVegetarian;
  final List<String> ingredientIds;
  final String? image;

  const FridgeRecipe({
    required this.id,
    required this.title,
    required this.description,
    required this.minutes,
    required this.ingredientIds,
    this.isVegetarian = false,
    this.image,
  });

  List<String> missingIngredients(Iterable<String> selectedIds) {
    final selected = selectedIds is Set<String>
        ? selectedIds
        : selectedIds.toSet();
    return ingredientIds.where((id) => !selected.contains(id)).toList();
  }

  factory FridgeRecipe.fromJson(Map<String, dynamic> json) => FridgeRecipe(
    id: JsonReader(json).string('id'),
    title: JsonReader(json).string('title'),
    description: JsonReader(json)
        .string('description', fallback: '', allowEmpty: true),
    minutes: JsonReader(json).integer('minutes', min: 1),
    ingredientIds: JsonReader(json).strings('ingredientIds', allowEmpty: false),
    isVegetarian: JsonReader(json).boolean('isVegetarian'),
    image: JsonReader(json).optionalString('image'),
  );

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    minutes,
    isVegetarian,
    ingredientIds,
    image,
  ];
}
