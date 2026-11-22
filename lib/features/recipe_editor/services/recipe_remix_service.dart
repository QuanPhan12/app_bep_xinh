import '../../recipe_detail/services/recipe_detail_service.dart';
import '../../recipes/models/recipe_remix.dart';
import '../models/recipe_draft.dart';
import 'recipe_authoring_repository.dart';
import 'recipe_editor_service.dart';

class RecipeRemixSeed {
  const RecipeRemixSeed(this.draft, this.previous);
  final RecipeDraft draft;
  final RecipeDraft? previous;
  bool get replacesDraft =>
      previous != null && previous!.remix?.recipeId != draft.remix!.recipeId;
}

class RecipeRemixService {
  const RecipeRemixService({required this.details, required this.editor});
  final RecipeDetailService details;
  final RecipeEditorService editor;
  Future<RecipeRemixSeed> load(String id) async {
    if (!RegExp(r'^r_[A-Za-z0-9_-]{1,62}$').hasMatch(id)) {
      throw const RecipeAuthoringException(
        'Chỉ có thể biến tấu công thức đã được duyệt.',
      );
    }
    final source = (await details.fetchRecipe(id)).recipe;
    if (source.id != id ||
        source.author.id == null ||
        source.contentHash == null) {
      throw const RecipeAuthoringException(
        'Không đọc được nguồn công thức công khai.',
      );
    }
    final previous = await editor.loadDraft();
    if (previous?.remix?.recipeId == id) {
      return RecipeRemixSeed(previous!, previous);
    }
    final base = RecipeDraft.fromContent(source.content);
    final remix = RecipeRemix.fromJson(
      RecipeRemix(
        recipeId: id,
        title: source.title,
        authorId: source.author.id!,
        authorName: source.author.name,
        sourceHash: source.contentHash!,
      ).toJson(),
    );
    return RecipeRemixSeed(
      base.copyWith(remix: remix, remixBaseline: base.contentFingerprint),
      previous,
    );
  }
}
