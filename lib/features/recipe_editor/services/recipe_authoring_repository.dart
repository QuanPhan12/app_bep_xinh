import '../../recipes/models/recipe_remix.dart';

class RecipeDraftRecord {
  final String submissionId;
  final int revision;
  final Map<String, dynamic>? draft;
  final String? revisionOf;
  final RecipeRemix? remix;
  const RecipeDraftRecord(
    this.submissionId,
    this.revision,
    this.draft, {
    this.revisionOf,
    this.remix,
  });
}

abstract interface class RecipeAuthoringRepository {
  Future<void> ensureActive();
  Future<RecipeDraftRecord> loadDraft();
  Future<int> saveDraft(RecipeDraftRecord record, Map<String, dynamic> draft);
  Future<void> submit(
    RecipeDraftRecord record,
    Map<String, dynamic> content,
    String hash,
    String catalogVersion,
  );
}

class RecipeAuthoringException implements Exception {
  final String message;
  const RecipeAuthoringException(this.message);
  @override
  String toString() => message;
}
