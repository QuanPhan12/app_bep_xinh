import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/recipe_draft.dart';
import '../validation/recipe_editor_validation.dart';

abstract interface class RecipeCoverPicker {
  Future<RecipeCover?> pickCover();
  Future<RecipeCover?> recoverLostCover();
}

abstract interface class CameraRecipeCoverPicker {
  Future<RecipeCover?> captureCover();
}

abstract interface class RecipePhotosPicker {
  Future<List<RecipeCover>> pickPhotos(int limit);
  Future<List<RecipeCover>> recoverLostPhotos();
}

class RecipeCoverException implements Exception {
  final String message;
  const RecipeCoverException(this.message);
}

class ImagePickerRecipeCoverPicker
    implements RecipeCoverPicker, CameraRecipeCoverPicker, RecipePhotosPicker {
  final ImagePicker picker;
  int _sequence = 0;

  ImagePickerRecipeCoverPicker({ImagePicker? picker})
    : picker = picker ?? ImagePicker();

  @override
  Future<RecipeCover?> pickCover() async {
    return _pick(ImageSource.gallery);
  }

  @override
  Future<RecipeCover?> captureCover() => _pick(ImageSource.camera);

  @override
  Future<List<RecipeCover>> pickPhotos(int limit) async {
    final files = await picker.pickMultiImage(
      limit: limit,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (files.length > limit) {
      throw RecipeCoverException('Chỉ có thể thêm tối đa $limit ảnh nữa.');
    }
    // Đọc lần lượt để không giải mã nhiều ảnh lớn cùng lúc trên thiết bị yếu.
    return [for (final file in files) await _read(file)];
  }

  Future<RecipeCover?> _pick(ImageSource source) async {
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    return file == null ? null : _read(file);
  }

  @override
  Future<RecipeCover?> recoverLostCover() async {
    final photos = await recoverLostPhotos();
    return photos.firstOrNull;
  }

  @override
  Future<List<RecipeCover>> recoverLostPhotos() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return [];
    final response = await picker.retrieveLostData();
    if (response.isEmpty) return [];
    if (response.exception != null) throw response.exception!;
    final files = response.files;
    if (files == null) return [];
    if (files.length > RecipeEditorLimits.maxPostPhotos) {
      throw const RecipeCoverException('Chỉ có thể khôi phục tối đa 10 ảnh.');
    }
    return [for (final file in files) await _read(file)];
  }

  Future<RecipeCover> _read(XFile file) async {
    if (await file.length() > RecipeEditorLimits.maxCoverBytes) {
      throw const RecipeCoverException('Chọn ảnh có dung lượng tối đa 8 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > RecipeEditorLimits.maxCoverBytes) {
      throw const RecipeCoverException(
        'Ảnh không hợp lệ hoặc có dung lượng quá lớn.',
      );
    }
    // Xác minh dữ liệu ảnh với vùng decode nhỏ, không giữ ảnh gốc đã giải mã.
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 320,
      targetHeight: 320,
    );
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
    return RecipeCover(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}',
      name: file.name,
      bytes: bytes,
    );
  }
}
