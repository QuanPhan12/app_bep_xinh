import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';

import 'dart:io';

import 'package:app_bep_xinh/features/recipe_editor/models/recipe_draft.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_cover_picker.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_editor_service.dart';

RecipeCover recipeCoverFixture({String id = 'cover'}) => RecipeCover(
  id: id,
  name: 'food.png',
  bytes: File('assets/images/logo.png').readAsBytesSync(),
);

RecipeDraft validRecipeDraft() => RecipeDraft(
  title: 'Trứng chiên hành',
  cover: recipeCoverFixture(),
  ingredients: const [
    RecipeIngredientDraft(
      id: 'ingredient_0',
      name: 'Trứng gà',
      ingredientId: 'egg',
      amount: 2,
      unit: IngredientUnit(id: 'fruit', label: 'quả'),
    ),
  ],
  steps: const [
    RecipeStepDraft(
      id: 'step_0',
      instruction: 'Đánh trứng với hành, chiên đến khi chín.',
    ),
  ],
);

class StubRecipeEditorService implements RecipeEditorService {
  RecipeDraft? saved;
  RecipeDraft? submitted;
  int loadCalls = 0;
  int saveCalls = 0;
  int submitCalls = 0;
  Future<RecipeDraft?> Function()? onLoad;
  Future<void> Function(RecipeDraft)? onSave;
  Future<void> Function(RecipeDraft)? onSubmit;

  @override
  Future<RecipeDraft?> loadDraft() {
    loadCalls++;
    return onLoad?.call() ?? Future.value(saved);
  }

  @override
  Future<void> saveDraft(RecipeDraft draft) async {
    saveCalls++;
    await onSave?.call(draft);
    saved = draft;
  }

  @override
  Future<void> submit(RecipeDraft draft) async {
    submitCalls++;
    await onSubmit?.call(draft);
    submitted = draft;
    saved = null;
  }
}

class StubRecipeCoverPicker implements RecipeCoverPicker {
  Future<RecipeCover?> Function()? onPick;
  Future<RecipeCover?> Function()? onRecover;
  int pickCalls = 0;

  @override
  Future<RecipeCover?> pickCover() {
    pickCalls++;
    return onPick?.call() ?? Future.value();
  }

  @override
  Future<RecipeCover?> recoverLostCover() =>
      onRecover?.call() ?? Future.value();
}
