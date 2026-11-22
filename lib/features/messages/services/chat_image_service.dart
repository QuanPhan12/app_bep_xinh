import '../../recipe_editor/services/recipe_cover_picker.dart';
import '../../recipe_editor/services/recipe_image_uploader.dart';
import '../../recipes/models/recipe_image.dart';

abstract interface class ChatImageService {
  Future<RecipeImage?> pick();
  Future<RecipeImage> upload(RecipeImage image);
}

/// Tái sử dụng bộ chọn đã xác minh bytes và uploader hiện có. Chỉ upload khi gửi,
/// không đưa tên file thiết bị vào hội thoại hoặc payload ảnh công khai.
class DefaultChatImageService implements ChatImageService {
  final RecipeCoverPicker picker;
  final RecipeImageUploader uploader;
  DefaultChatImageService({required this.picker, required this.uploader});

  @override
  Future<RecipeImage?> pick() async {
    final selected = await picker.pickCover();
    return selected == null
        ? null
        : RecipeImage.memory(
            id: selected.id,
            name: 'Ảnh trò chuyện',
            bytes: selected.bytes,
          );
  }

  @override
  Future<RecipeImage> upload(RecipeImage image) => uploader.upload(image);
}
