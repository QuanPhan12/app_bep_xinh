import 'dart:convert';
import 'dart:async';

import 'package:crypto/crypto.dart';

import '../../../core/utils/async_serial_queue.dart';
import '../../ingredients/services/ingredient_catalog_service.dart';
import '../models/recipe_draft.dart';
import '../validation/recipe_editor_validation.dart';
import 'recipe_authoring_repository.dart';
import 'recipe_draft_codec.dart';
import 'recipe_editor_service.dart';
import 'recipe_image_uploader.dart';

/// Điều phối upload và ghi dữ liệu; widget/Cubit không gọi HTTP hoặc Firestore.
class FirestoreRecipeEditorService
    implements RecipeEditorService, RecipeEditorProgressSource {
  final _progress = StreamController<String>.broadcast();
  @override
  Stream<String> get progress => _progress.stream;
  void _report(String value) {
    if (!_progress.isClosed) _progress.add(value);
  }

  @override
  Future<void> dispose() => _progress.close();
  final RecipeAuthoringRepository repository;
  final RecipeImageUploader uploader;
  final IngredientCatalogService catalog;
  final _writes = AsyncSerialQueue();
  RecipeDraftRecord? _record;
  FirestoreRecipeEditorService({
    required this.repository,
    required this.uploader,
    required this.catalog,
  });

  @override
  Future<RecipeDraft?> loadDraft() async {
    await _writes.settled;
    final record = await repository.loadDraft();
    _record = record;
    return record.draft == null
        ? null
        : RecipeDraftCodec.decode(record.draft!, await catalog.fetchCatalog());
  }

  Future<RecipeDraft> _upload(RecipeDraft draft) async {
    if (draft.photos.length >= RecipeLimits.maxPostPhotos) {
      throw const RecipeAuthoringException('Mỗi bài đăng có tối đa 10 ảnh.');
    }
    final total =
        (draft.cover == null ? 0 : 1) +
        draft.photos.length +
        draft.steps.where((s) => s.photo != null).length;
    var completed = 0;
    _report('Đang tải ảnh: $completed/$total');
    final cover = draft.cover == null
        ? null
        : await uploader.upload(draft.cover!);
    if (draft.cover != null) {
      completed++;
      _report('Đang tải ảnh: $completed/$total');
    }
    final photos = <RecipeImage>[];
    for (final image in draft.photos) {
      photos.add(await uploader.upload(image));
      completed++;
      _report('Đang tải ảnh: $completed/$total');
    }
    final steps = <RecipeStepDraft>[];
    for (final step in draft.steps) {
      steps.add(
        step.photo == null
            ? step
            : step.copyWith(photo: await uploader.upload(step.photo!)),
      );
      if (step.photo != null) {
        completed++;
        _report('Đang tải ảnh: $completed/$total');
      }
    }
    return draft.copyWith(cover: cover, photos: photos, steps: steps);
  }

  RecipeDraftRecord get _current =>
      _record ?? (throw StateError('Draft not loaded'));

  RecipeDraftRecord _recordFor(RecipeDraft draft) {
    final previousSource = (_current.draft?['remix'] as Map?)?['recipeId'];
    return RecipeDraftRecord(
      _current.submissionId,
      _current.revision,
      _current.draft,
      revisionOf: previousSource == draft.remix?.recipeId
          ? _current.revisionOf
          : null,
      remix: draft.remix,
    );
  }

  @override
  Future<void> saveDraft(RecipeDraft draft) => _writes.run(() async {
    await repository.ensureActive();
    final uploaded = await _upload(draft);
    final data = RecipeDraftCodec.encode(uploaded);
    _report('Đang lưu bản nháp…');
    if (utf8.encode(jsonEncode(data)).length > 400000) {
      throw const RecipeAuthoringException(
        'Bản nháp quá lớn. Vui lòng giảm nội dung.',
      );
    }
    final record = _recordFor(uploaded);
    final revision = await repository.saveDraft(record, data);
    _record = RecipeDraftRecord(
      _current.submissionId,
      revision,
      data,
      revisionOf: record.revisionOf,
    );
  });

  @override
  Future<void> submit(RecipeDraft draft) => _writes.run(() async {
    _report('Đang kiểm tra công thức…');
    final normalized = draft.normalized();
    if (RecipeEditorValidation.validate(normalized).isNotEmpty) {
      throw const FormatException('Invalid recipe');
    }
    await repository.ensureActive();
    final ingredients = await catalog.fetchCatalog();
    // Xác thực nguyên liệu/đơn vị trước khi tốn chi phí upload.
    RecipeContent.fromJson(normalized.toRecipeContent().toJson(), ingredients);
    final uploaded = await _upload(normalized);
    final content = RecipeContent.fromJson(
      uploaded.toRecipeContent().toJson(),
      ingredients,
    ).toJson();
    final json = jsonEncode(
      uploaded.remix == null
          ? content
          : {'content': content, 'remix': uploaded.remix!.toJson()},
    );
    if (utf8.encode(json).length > 400000) {
      throw const RecipeAuthoringException(
        'Công thức quá lớn. Vui lòng giảm nội dung.',
      );
    }
    final hash = sha256.convert(utf8.encode(json)).toString();
    _report('Đang gửi công thức chờ duyệt…');
    await repository.submit(
      _recordFor(uploaded),
      content,
      hash,
      ingredients.version ?? 'legacy',
    );
  });
}
