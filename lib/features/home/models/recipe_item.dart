import '../../recipes/models/recipe_remix.dart';

import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_content.dart';
import 'package:app_bep_xinh/features/recipes/presentation/recipe_labels.dart';

/// Model đại diện cho một món ăn trên màn hình Trang chủ & Khám phá
class RecipeItem extends Equatable {
  final RecipeRemix? remix;
  final String id;
  final String title;
  final String image;
  final List<RecipeImage> photos;
  List<String> get imageSources => [
    image,
    ...photos.map((photo) => photo.source ?? ""),
  ];
  final double rating;
  final int cookTimeMinutes;
  final String tag;
  final String difficulty;
  final int? calories;
  final bool isFavorite;
  final int likeCount, commentCount, shareCount;
  final String? authorId;
  final String? authorName;

  const RecipeItem({
    this.remix,
    required this.id,
    required this.title,
    required this.image,
    this.photos = const [],
    required this.rating,
    required this.cookTimeMinutes,
    required this.tag,
    this.difficulty = 'Dễ làm',
    this.calories,
    this.isFavorite = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.authorId,
    this.authorName,
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
    int? likeCount,
    int? commentCount,
    int? shareCount,
  }) {
    return RecipeItem(
      remix: remix,
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
      photos: photos,
      rating: rating ?? this.rating,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      tag: tag ?? this.tag,
      difficulty: difficulty ?? this.difficulty,
      calories: calories ?? this.calories,
      isFavorite: isFavorite ?? this.isFavorite,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      authorId: authorId,
      authorName: authorName,
    );
  }

  factory RecipeItem.fromJson(Map<String, dynamic> json) => RecipeItem(
    remix: json['remix'] == null
        ? null
        : RecipeRemix.fromJson(Map<String, dynamic>.from(json['remix'] as Map)),
    id: JsonReader(json).string('id'),
    title: JsonReader(json).string('title'),
    image: JsonReader(json).string('image'),
    rating: JsonReader(json).number('rating', max: 5),
    cookTimeMinutes: JsonReader(json).integer('cookTimeMinutes', min: 1),
    tag: JsonReader(json).string('tag'),
    difficulty: JsonReader(json).string('difficulty'),
    calories: JsonReader(json).optionalInteger('calories'),
    isFavorite: JsonReader(json).boolean('isFavorite'),
    likeCount: _count(json, 'likeCount'),
    commentCount: _count(json, 'commentCount'),
    shareCount: _count(json, 'shareCount'),
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
        : RecipeImage.fromJson(cover as Map<String, dynamic>).source;
    final difficulty = RecipeDifficulty.parse(reader.string('difficulty'))
        .label;
    return RecipeItem(
      remix: json['remix'] == null
          ? null
          : RecipeRemix.fromJson(
              Map<String, dynamic>.from(json['remix'] as Map),
            ),
      id: reader.string('id'),
      authorId: json['author'] is Map
          ? (json['author'] as Map)['id'] as String?
          : null,
      authorName: json['author'] is Map
          ? (json['author'] as Map)['name'] as String?
          : json['author'] is String
          ? json['author'] as String
          : null,
      title: reader.string('title'),
      image: image ?? '',
      photos: decodeRecipePhotos(json['photos']),
      rating: json['rating'] == null ? 0 : reader.number('rating', max: 5),
      cookTimeMinutes:
          reader.integer('preparationMinutes') +
          reader.integer('cookingMinutes', min: 1),
      tag: difficulty,
      difficulty: difficulty,
      calories: reader.optionalInteger('calories'),
      isFavorite: isFavorite,
      likeCount: _count(json, 'likeCount'),
      commentCount: _count(json, 'commentCount'),
      shareCount: _count(json, 'shareCount'),
    );
  }

  @override
  List<Object?> get props => [
    remix,
    id,
    title,
    image,
    photos,
    rating,
    cookTimeMinutes,
    tag,
    difficulty,
    calories,
    isFavorite,
    likeCount,
    commentCount,
    shareCount,
    authorId,
    authorName,
  ];

  static int _count(Map<String, dynamic> json, String key) {
    final engagement = json['engagement'];
    if (engagement == null) return 0;
    if (engagement is! Map<String, dynamic>) {
      throw const FormatException('Invalid recipe engagement');
    }
    return JsonReader(engagement).optionalInteger(key) ?? 0;
  }
}
