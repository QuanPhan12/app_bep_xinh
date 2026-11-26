import 'dart:convert';
import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../recipes/models/recipe_image.dart';
import '../../recipes/models/recipe_limits.dart';
import 'recipe_image_uploader.dart';

class CloudinaryRecipeImageUploader implements RecipeImageUploader {
  static const cloudName = 'ddqouziau';
  static const uploadPreset = 'bep_xinh';
  final http.Client client;
  final String uploadTag;
  final _completed = <String, RecipeImage>{};
  final _pending = <String, Future<RecipeImage>>{};
  CloudinaryRecipeImageUploader(
    this.client, {
    this.uploadTag = 'bep_xinh_recipe',
  });

  @override
  Future<RecipeImage> upload(RecipeImage image) async {
    if (image.url != null) return RecipeImage.fromJson(image.toJson());
    final bytes = image.bytes;
    if (bytes == null ||
        bytes.isEmpty ||
        bytes.length > RecipeLimits.maxCoverBytes) {
      throw const RecipeUploadException(
        'Ảnh phải có dung lượng từ 1 byte đến 8 MB.',
      );
    }
    final hash = sha256.convert(bytes).toString();
    final cached = _completed[hash];
    if (cached != null) return _withIdentity(cached, image);
    final uploaded = await (_pending[hash] ??= _upload(image)
        .then((value) {
          _completed[hash] = value;
          return value;
        })
        .whenComplete(() {
          _pending.remove(hash);
        }));
    return _withIdentity(uploaded, image);
  }

  // Cache dùng bytes để tránh upload lại; ID của từng ô ảnh vẫn thuộc bản nháp.
  RecipeImage _withIdentity(RecipeImage uploaded, RecipeImage original) =>
      RecipeImage.remote(
        id: original.id,
        name: original.name,
        url: uploaded.url,
        publicId: uploaded.publicId,
      );

  Future<RecipeImage> _upload(RecipeImage image) async {
    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.https('api.cloudinary.com', '/v1_1/$cloudName/image/upload'),
            )
            ..fields['upload_preset'] = uploadPreset
            ..fields['tags'] = uploadTag
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                image.bytes!,
                filename: 'recipe_image',
              ),
            );
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 60));
      final body = await response.stream.bytesToString().timeout(
        const Duration(seconds: 30),
      );
      if (body.length > 100000) {
        throw const FormatException('Upload response too large');
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        final message = (data['error'] as Map?)?['message']?.toString() ?? '';
        if (message.contains('whitelisted') || message.contains('preset')) {
          throw const RecipeUploadException(
            'Preset ảnh chưa bật unsigned upload. Vui lòng liên hệ quản trị viên.',
          );
        }
        throw const RecipeUploadException(
          'Không tải được ảnh lên. Vui lòng thử lại.',
        );
      }
      if (data['resource_type'] != 'image' ||
          data['bytes'] is! num ||
          (data['bytes'] as num) <= 0 ||
          (data['bytes'] as num) > RecipeLimits.maxCoverBytes ||
          !['jpg', 'jpeg', 'png', 'webp'].contains(data['format'])) {
        throw const FormatException('Unexpected uploaded image');
      }
      return RecipeImage.fromJson({
        'id': image.id,
        'name': image.name,
        'url': data['secure_url'],
        'publicId': data['public_id'],
      });
    } on RecipeUploadException {
      rethrow;
    } catch (_) {
      throw const RecipeUploadException(
        'Tải ảnh chưa hoàn tất. Kiểm tra kết nối và thử lại.',
      );
    }
  }
}
