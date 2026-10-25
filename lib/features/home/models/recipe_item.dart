import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_content.dart';
import 'package:app_bep_xinh/features/recipes/presentation/recipe_labels.dart';

/// Model đại diện cho một món ăn trên màn hình Trang chủ & Khám phá
class RecipeItem extends Equatable {
  final String id;
  final String title;
  final String image;
  final double rating;
  final int cookTimeMinutes;
  final String tag;
  final String difficulty;
  final int? calories;
  final bool isFavorite;

  const RecipeItem({
    required this.id,
    required this.title,
    required this.image,
    required this.rating,
    required this.cookTimeMinutes,
    required this.tag,
    this.difficulty = 'Dễ làm',
    this.calories,
    this.isFavorite = false,
  });

  RecipeItem copyWith({
    String? id,
    String? title,
    String? image,
    double? rating,
    int? cookTimeMinutes,
    String? tag,
    String? difficulty,
    int? calories,
    bool? isFavorite,
  }) {
    return RecipeItem(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      tag: tag ?? this.tag,
      difficulty: difficulty ?? this.difficulty,
      calories: calories ?? this.calories,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory RecipeItem.fromJson(Map<String, dynamic> json) => RecipeItem(
    id: JsonReader(json).string('id'),
    title: JsonReader(json).string('title'),
    image: JsonReader(json).string('image'),
    rating: JsonReader(json).number('rating', max: 5),
    cookTimeMinutes: JsonReader(json).integer('cookTimeMinutes', min: 1),
    tag: JsonReader(json).string('tag'),
    difficulty: JsonReader(json).string('difficulty'),
    calories: JsonReader(json).optionalInteger('calories'),
    isFavorite: JsonReader(json).boolean('isFavorite'),
  );

  factory RecipeItem.fromRecipeJson(
    Map<String, dynamic> json, {
    required bool isFavorite,
  }) {
    final reader = JsonReader(json);
    final cover = json['cover'];
    if (cover != null && cover is! Map<String, dynamic>) {
      throw const FormatException('Invalid recipe cover');
    }
    final image = cover == null
        ? reader.optionalString('image')
        : RecipeImage.fromJson(cover as Map<String, dynamic>).assetPath;
    final difficulty = RecipeDifficulty.parse(reader.string('difficulty'))
        .label;
    return RecipeItem(
      id: reader.string('id'),
      title: reader.string('title'),
      image: image ?? '',
      rating: json['rating'] == null ? 0 : reader.number('rating', max: 5),
      cookTimeMinutes:
          reader.integer('preparationMinutes') +
          reader.integer('cookingMinutes', min: 1),
      tag: difficulty,
      difficulty: difficulty,
      calories: reader.optionalInteger('calories'),
      isFavorite: isFavorite,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    image,
    rating,
    cookTimeMinutes,
    tag,
    difficulty,
    calories,
    isFavorite,
  ];
}
