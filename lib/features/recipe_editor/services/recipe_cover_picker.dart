import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/recipe_draft.dart';
import '../validation/recipe_editor_validation.dart';

abstract interface class RecipeCoverPicker {
  Future<RecipeCover?> pickCover();
  Future<RecipeCover?> recoverLostCover();
}

class RecipeCoverException implements Exception {
  final String message;
  const RecipeCoverException(this.message);
}

class ImagePickerRecipeCoverPicker implements RecipeCoverPicker {
  final ImagePicker picker;
  int _sequence = 0;

  ImagePickerRecipeCoverPicker({ImagePicker? picker})
    : picker = picker ?? ImagePicker();

  @override
  Future<RecipeCover?> pickCover() async {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    return file == null ? null : _read(file);
  }

  @override
  Future<RecipeCover?> recoverLostCover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final response = await picker.retrieveLostData();
    if (response.isEmpty) return null;
    if (response.exception != null) throw response.exception!;
    final files = response.files;
    return files == null || files.isEmpty ? null : _read(files.first);
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
