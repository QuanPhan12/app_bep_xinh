import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:equatable/equatable.dart';

class RecipeAuthor extends Equatable {
  final String? id;
  final String name;
  final String handle;
  final String? avatarAsset;
  const RecipeAuthor({
    required String this.id,
    required this.name,
    this.handle = '',
    this.avatarAsset,
  });
  const RecipeAuthor.legacy({required this.name})
    : id = null,
      handle = '',
      avatarAsset = null;

  factory RecipeAuthor.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return RecipeAuthor(
      id: reader.string('id'),
      name: reader.string('name'),
      handle: reader.string('handle', fallback: '', allowEmpty: true),
      avatarAsset: reader.optionalString('avatarAsset'),
    );
  }
  static RecipeAuthor read(Object? value) {
    if (value is Map<String, dynamic>) return RecipeAuthor.fromJson(value);
    if (value is String && value.trim().isNotEmpty) {
      return RecipeAuthor.legacy(name: value);
    }
    throw const FormatException('Invalid recipe author');
  }

  @override
  List<Object?> get props => [id, name, handle, avatarAsset];
}
