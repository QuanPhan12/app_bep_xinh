import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';

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

  @override
  List<Object> get props => [id, title, description, image, tag, cookTime];
}
