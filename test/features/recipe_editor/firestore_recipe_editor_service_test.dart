import 'package:app_bep_xinh/features/recipes/models/recipe_remix.dart';

import 'dart:convert';

import 'package:app_bep_xinh/features/recipe_editor/services/firestore_recipe_editor_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_authoring_repository.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_draft_codec.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_image_uploader.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_image.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/recipe_editor_fakes.dart';
import '../../support/mock_services.dart';

class MemoryAuthoringRepository implements RecipeAuthoringRepository {
  RecipeDraftRecord record = const RecipeDraftRecord('r_test', 0, null);
  Map<String, dynamic>? submitted;
  RecipeDraftRecord? submittedRecord;
  String? hash;
  int writes = 0;
  bool fail = false;
  @override
  Future<void> ensureActive() async {}
  @override
  Future<RecipeDraftRecord> loadDraft() async => record;
  @override
  Future<int> saveDraft(
    RecipeDraftRecord expected,
    Map<String, dynamic> draft,
  ) async {
    record = RecipeDraftRecord(
      expected.submissionId,
      expected.revision + 1,
      draft,
    );
    return record.revision;
  }

  @override
  Future<void> submit(
    RecipeDraftRecord expected,
    Map<String, dynamic> content,
    String value,
    String version,
  ) async {
    if (submitted != null) {
      expect(value, hash);
      return;
    }
    submittedRecord = expected;
    submitted = content;
    hash = value;
    writes++;
    if (fail) throw StateError('response lost after commit');
  }
}

class TestImageUploader implements RecipeImageUploader {
  int calls = 0;
  bool fail = false;
  @override
  Future<RecipeImage> upload(RecipeImage image) async {
    calls++;
    if (fail) throw const RecipeUploadException('Ảnh chưa tải được');
    return RecipeImage.remote(
      id: image.id,
      name: image.name,
      url:
          'https://res.cloudinary.com/ddqouziau/image/upload/v1/${image.id}.png',
      publicId: image.id,
    );
  }
}

void main() {
  late MemoryAuthoringRepository repository;
  late TestImageUploader uploader;
  late FirestoreRecipeEditorService service;
  setUp(() {
    repository = MemoryAuthoringRepository();
    uploader = TestImageUploader();
    service = FirestoreRecipeEditorService(
      repository: repository,
      uploader: uploader,
      catalog: MockIngredientCatalogService(fixtureApi()),
    );
  });
  test(
    'remix source survives save/load and is included in submission identity',
    () async {
      await service.loadDraft();
      final base = validRecipeDraft();
      final remix = RecipeRemix(
        recipeId: 'r_source',
        title: base.title,
        authorId: 'original',
        authorName: 'Bếp gốc',
        sourceHash: List.filled(64, 'a').join(),
        changes: 'Giảm dầu khi chiên và thêm hành.',
      );
      final draft = base.copyWith(
        remix: remix,
        remixBaseline: base.contentFingerprint,
        description: 'Phiên bản ít dầu hơn.',
      );
      await service.saveDraft(draft);
      final loaded = await service.loadDraft();
      expect(loaded!.remix, remix);
      expect(loaded.remixBaseline, base.contentFingerprint);
      await service.submit(loaded);
      expect(repository.submittedRecord!.remix, remix);
      expect(repository.submitted, isNot(contains('remix')));
      final firstHash = repository.hash;
      final secondRepository = MemoryAuthoringRepository();
      final second = FirestoreRecipeEditorService(
        repository: secondRepository,
        uploader: uploader,
        catalog: MockIngredientCatalogService(fixtureApi()),
      );
      await second.loadDraft();
      await second.submit(
        loaded.copyWith(
          remix: remix.withChanges('Thêm hành và giảm dầu ở bước chiên.'),
        ),
      );
      expect(secondRepository.hash, isNot(firstHash));
      await second.dispose();
    },
  );

  test('incomplete draft persists references and restores without embedding image bytes', () async {
    expect(await service.loadDraft(), isNull);
    final draft = validRecipeDraft().copyWith(title: '');
    await service.saveDraft(draft);
    final data = repository.record.draft!;
    expect(jsonEncode(data), isNot(contains('bytesBase64')));
    final restored = await service.loadDraft();
    expect(restored!.title, '');
    expect(restored.cover!.url, isNotNull);
    expect(RecipeDraftCodec.encode(restored), data);
  });
  test('submission validates first and sends a stable hash/content without images inline', () async {
    await service.loadDraft();
    await expectLater(
      service.submit(validRecipeDraft().copyWith(title: '')),
      throwsFormatException,
    );
    expect(uploader.calls, 0);
    expect(repository.writes, 0);
    await service.submit(validRecipeDraft());
    expect(repository.hash!.length, 64);
    expect(jsonEncode(repository.submitted), isNot(contains('bytesBase64')));
    expect(repository.submitted!['title'], validRecipeDraft().title);
    expect(repository.submitted!['isBanner'], isFalse);
  });
  test('uncertain commit retry reuses submission ID and does not create duplicate posts', () async {
    await service.loadDraft();
    repository.fail = true;
    await expectLater(service.submit(validRecipeDraft()), throwsStateError);
    repository.fail = false;
    await service.submit(validRecipeDraft());
    expect(repository.writes, 1);
    expect(repository.record.submissionId, 'r_test');
  });
  test('image upload failure never submits a half-complete recipe', () async {
    await service.loadDraft();
    uploader.fail = true;
    await expectLater(
      service.submit(validRecipeDraft()),
      throwsA(isA<RecipeUploadException>()),
    );
    expect(repository.submitted, isNull);
    expect(repository.record.draft, isNull);
  });
}
