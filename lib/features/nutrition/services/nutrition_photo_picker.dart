import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import '../../ai_chat/models/ai_message.dart';

abstract interface class NutritionPhotoPicker {
  Future<Uint8List?> pick({bool camera = false});
}

class DeviceNutritionPhotoPicker implements NutritionPhotoPicker {
  final ImagePicker picker;
  DeviceNutritionPhotoPicker({ImagePicker? picker})
    : picker = picker ?? ImagePicker();
  @override
  Future<Uint8List?> pick({bool camera = false}) async {
    final file = await picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    if (await file.length() > 8 * 1024 * 1024) {
      throw const AiChatFailure('Chọn ảnh có dung lượng tối đa 8 MB.');
    }
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 960,
      allowUpscaling: false,
    );
    try {
      final frame = await codec.getNextFrame();
      try {
        // Mã hóa lại để không chuyển EXIF/vị trí của ảnh gốc sang dịch vụ AI.
        final png = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (png == null || png.lengthInBytes > 4 * 1024 * 1024) {
          throw const AiChatFailure(
            'Ảnh quá lớn để phân tích. Chọn ảnh nhỏ hơn.',
          );
        }
        return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}
