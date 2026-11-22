import 'dart:convert';
import 'dart:typed_data';

import 'package:app_bep_xinh/features/recipe_editor/services/cloudinary_recipe_image_uploader.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_image_uploader.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

RecipeCover photo(String id) => RecipeCover(
  id: id,
  name: 'image.png',
  bytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
);
void main() {
  test(
    'upload uses configured cloud/preset and caches identical file bytes',
    () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(
          request.url.toString(),
          'https://api.cloudinary.com/v1_1/ddqouziau/image/upload',
        );
        expect(latin1.decode(request.bodyBytes), contains('bep_xinh'));
        expect(latin1.decode(request.bodyBytes), isNot(contains('api_secret')));
        return http.Response(
          jsonEncode({
            'resource_type': 'image',
            'bytes': 8,
            'format': 'png',
            'secure_url':
                'https://res.cloudinary.com/ddqouziau/image/upload/v1/test.png',
            'public_id': 'test',
          }),
          200,
        );
      });
      addTearDown(client.close);
      final uploader = CloudinaryRecipeImageUploader(client);
      final image = await uploader.upload(photo('a'));
      expect(image.bytes, isNull);
      expect(image.publicId, 'test');
      expect((await uploader.upload(photo('b'))).url, image.url);
      expect((await uploader.upload(image)).url, image.url);
      expect(calls, 1);
    },
  );
  test(
    'disabled preset reports actionable error and retry can upload again',
    () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode({
            'error': {
              'message':
                  'Upload preset must be whitelisted for unsigned uploads',
            },
          }),
          400,
        );
      });
      addTearDown(client.close);
      final uploader = CloudinaryRecipeImageUploader(client);
      for (var i = 0; i < 2; i++) {
        await expectLater(
          uploader.upload(photo('a')),
          throwsA(
            isA<RecipeUploadException>().having(
              (e) => e.message,
              'message',
              contains('unsigned'),
            ),
          ),
        );
      }
      expect(calls, 2);
    },
  );
  test(
    'foreign delivery URL and oversized files never become persisted images',
    () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode({
            'resource_type': 'image',
            'bytes': 8,
            'format': 'png',
            'secure_url': 'https://evil.test/photo.png',
            'public_id': 'test',
          }),
          200,
        );
      });
      addTearDown(client.close);
      final uploader = CloudinaryRecipeImageUploader(client);
      await expectLater(
        uploader.upload(photo('a')),
        throwsA(isA<RecipeUploadException>()),
      );
      await expectLater(
        uploader.upload(
          RecipeCover(
            id: 'b',
            name: 'big',
            bytes: Uint8List(8 * 1024 * 1024 + 1),
          ),
        ),
        throwsA(isA<RecipeUploadException>()),
      );
      expect(calls, 1);
    },
  );
}
