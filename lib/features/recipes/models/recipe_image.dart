import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';

import 'recipe_limits.dart';

/// A bundled fixture image or the immutable bytes selected in the editor.
class RecipeImage extends Equatable {
  final String id;
  final String name;
  final String? assetPath;
  final Uint8List? _bytes;
  Uint8List? get bytes => _bytes;

  const RecipeImage.asset({
    required this.id,
    required String this.assetPath,
    this.name = '',
  }) : _bytes = null;
  factory RecipeImage.memory({
    required String id,
    required String name,
    required Uint8List bytes,
  }) = RecipeCover;

  RecipeImage._memory({
    required this.id,
    required this.name,
    required Uint8List bytes,
  }) : assetPath = null,
       _bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  factory RecipeImage.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final id = reader.string('id');
    final name = reader.string('name', fallback: '', allowEmpty: true);
    final asset = reader.optionalString('assetPath');
    final encoded = reader.optionalString('bytesBase64');
    if ((asset == null) == (encoded == null)) {
      throw const FormatException('Image needs exactly one source');
    }
    if (asset != null) {
      return RecipeImage.asset(id: id, assetPath: asset, name: name);
    }
    if (encoded!.length > ((RecipeLimits.maxCoverBytes + 2) ~/ 3) * 4) {
      throw const FormatException('Image is too large');
    }
    final bytes = base64Decode(encoded);
    if (bytes.isEmpty || bytes.length > RecipeLimits.maxCoverBytes) {
      throw const FormatException('Invalid image bytes');
    }
    return RecipeImage.memory(id: id, name: name, bytes: bytes);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (assetPath != null) 'assetPath': assetPath,
    if (_bytes != null) 'bytesBase64': base64Encode(_bytes),
  };

  @override
  List<Object?> get props => [id, assetPath];
}

/// Kept as the editor's byte-only image type.
class RecipeCover extends RecipeImage {
  RecipeCover({required super.id, required super.name, required super.bytes})
    : super._memory();
  @override
  Uint8List get bytes => super.bytes!;
}
