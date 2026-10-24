import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';

import 'dart:io';
import 'dart:typed_data';

import 'package:app_bep_xinh/features/recipe_editor/models/recipe_draft.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_cover_picker.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_editor_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/validation/recipe_editor_validation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import '../../support/mock_services.dart';
import '../../support/recipe_editor_fakes.dart';

class TestImagePicker extends ImagePicker {
  XFile? result;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mock draft saves partially, survives reads and is cleared after valid submission', () async {
    final service = MockRecipeEditorService(
      fixtureApi(),
      MockIngredientCatalogService(fixtureApi()),
    );
    expect(await service.loadDraft(), isNull);
    final draft = RecipeDraft(title: 'Chưa hoàn tất');
    await service.saveDraft(draft);
    expect(await service.loadDraft(), draft);
    await expectLater(service.submit(draft), throwsFormatException);
    expect(await service.loadDraft(), draft);
    await service.submit(validRecipeDraft());
    expect(await service.loadDraft(), isNull);
  });

  test('photo adapter handles cancel, actual image bytes, oversize and corrupt data', () async {
    final picker = TestImagePicker();
    final adapter = ImagePickerRecipeCoverPicker(picker: picker);
    expect(await adapter.pickCover(), isNull);
    picker.result = XFile.fromData(
      File('assets/images/logo.png').readAsBytesSync(),
      name: 'food.png',
      mimeType: 'image/png',
    );
    final image = await adapter.pickCover();
    expect(image!.bytes, isNotEmpty);
    expect(() => image.bytes[0] = 0, throwsUnsupportedError);
    picker.result = XFile.fromData(
      Uint8List(RecipeEditorLimits.maxCoverBytes + 1),
      name: 'huge.png',
    );
    await expectLater(
      adapter.pickCover(),
      throwsA(isA<RecipeCoverException>()),
    );
    picker.result = XFile.fromData(
      Uint8List.fromList([1, 2, 3]),
      name: 'broken.png',
    );
    await expectLater(adapter.pickCover(), throwsA(isA<Exception>()));
  });
}
