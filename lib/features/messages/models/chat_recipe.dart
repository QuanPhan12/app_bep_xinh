import 'package:equatable/equatable.dart';

import '../../../core/services/json_reader.dart';
import '../../recipes/models/recipe_image.dart';

/// Snapshot món công khai tại thời điểm gửi; lịch sử chat không phụ thuộc danh sách Home.
class ChatRecipe extends Equatable {
  const ChatRecipe({
    required this.id,
    required this.title,
    required this.cover,
  });
  final String id, title;
  final RecipeImage cover;
  factory ChatRecipe.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    final value = ChatRecipe(
      id: r.string('id'),
      title: r.string('title'),
      cover: RecipeImage.fromJson(
        Map<String, dynamic>.from(json['cover'] as Map),
      ),
    );
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(value.id) ||
        value.title.length > 80 ||
        value.cover.url == null ||
        value.cover.publicId == null) {
      throw const FormatException('Invalid chat recipe');
    }
    return value;
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'cover': cover.toJson(),
  };
  @override
  List<Object?> get props => [id, title, cover];
}
