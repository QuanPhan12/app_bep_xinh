import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';

import '../../recipes/models/recipe_image.dart';

class HomeBannerItem extends Equatable {
  final String id;
  final String title;
  final String description;
  final String image;
  final String tag;
  final String cookTime;

  const HomeBannerItem({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.tag,
    required this.cookTime,
  });

  factory HomeBannerItem.fromJson(Map<String, dynamic> json) => HomeBannerItem(
    id: JsonReader(json).string('id'),
    title: JsonReader(json).string('title'),
    description: JsonReader(json)
        .string('description', fallback: '', allowEmpty: true),
    image: JsonReader(json).string('image'),
    tag: JsonReader(json).string('tag'),
    cookTime: JsonReader(json).string('cookTime'),
  );

  factory HomeBannerItem.fromRecipeJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final cover = RecipeImage.fromJson(json['cover'] as Map<String, dynamic>);
    return HomeBannerItem(
      id: reader.string('id'),
      title: reader.string('title'),
      description: reader.string('description', fallback: '', allowEmpty: true),
      image: cover.source!,
      tag: 'Món nổi bật',
      cookTime:
          '${reader.integer('preparationMinutes') + reader.integer('cookingMinutes')} phút',
    );
  }

  @override
  List<Object> get props => [id, title, description, image, tag, cookTime];
}
