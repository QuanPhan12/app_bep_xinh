import '../../recipes/models/recipe_image.dart';

class RecipeUploadException implements Exception {
  final String message;
  const RecipeUploadException(this.message);
  @override
  String toString() => message;
}

abstract interface class RecipeImageUploader {
  Future<RecipeImage> upload(RecipeImage image);
}
