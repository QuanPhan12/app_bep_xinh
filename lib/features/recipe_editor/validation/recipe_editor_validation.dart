import '../models/recipe_draft.dart';

typedef RecipeEditorLimits = RecipeLimits;

class RecipeEditorValidation {
  const RecipeEditorValidation._();
  static String ingredientError(String id) => 'ingredient.$id';
  static String stepInstruction(String id) => 'step.$id';

  static Map<String, String> validateIngredient(RecipeIngredientDraft item) {
    final errors = <String, String>{};
    if (item.name.trim().isEmpty) {
      errors['name'] = 'Nhập tên nguyên liệu.';
    } else if (item.name.length > RecipeEditorLimits.ingredientNameLength) {
      errors['name'] = 'Tên nguyên liệu quá dài.';
    }
    if (!item.toTaste) {
      final amount = item.amount;
      if (amount == null ||
          !amount.isFinite ||
          amount <= 0 ||
          amount != amount.truncateToDouble() ||
          amount > RecipeEditorLimits.maxIngredientAmount) {
        errors['amount'] = 'Nhập lượng dùng là số nguyên từ 1 đến 100.000.';
      }
      if (item.unit == null || item.unitId!.trim().isEmpty) {
        errors['unit'] = 'Chọn đơn vị.';
      }
    }
    if (item.note.length > RecipeEditorLimits.ingredientNoteLength) {
      errors['note'] = 'Ghi chú tối đa 160 ký tự.';
    }
    return Map.unmodifiable(errors);
  }

  static Map<String, String> validate(RecipeDraft draft) {
    final errors = <String, String>{};
    if (draft.cover == null) errors['cover'] = 'Thêm ảnh bìa cho món ăn.';
    if (draft.title.trim().isEmpty) {
      errors['title'] = 'Nhập tên món ăn.';
    } else if (draft.title.length > RecipeEditorLimits.titleLength) {
      errors['title'] =
          'Tên món ăn tối đa ${RecipeEditorLimits.titleLength} ký tự.';
    }
    if (draft.description.length > RecipeEditorLimits.descriptionLength) {
      errors['description'] = 'Mô tả tối đa 500 ký tự.';
    }
    if (draft.storageNotes.length > RecipeEditorLimits.noteLength) {
      errors['storageNotes'] = 'Ghi chú tối đa 500 ký tự.';
    }
    final groupIds = draft.ingredientGroups.map((group) => group.id).toSet();
    if (draft.ingredientGroups.isEmpty ||
        draft.ingredientGroups.length > RecipeEditorLimits.groups ||
        groupIds.length != draft.ingredientGroups.length) {
      errors['groups'] = 'Cần từ 1 đến 8 nhóm nguyên liệu có mã riêng.';
    }
    for (final group in draft.ingredientGroups) {
      if (group.name.trim().isEmpty ||
          group.name.length > RecipeEditorLimits.groupNameLength) {
        errors['group.${group.id}'] = 'Tên nhóm từ 1 đến 60 ký tự.';
      }
    }
    final preparation = int.tryParse(draft.preparationMinutes);
    if (preparation == null || preparation < 0 || preparation > 240) {
      errors['preparation'] = 'Nhập từ 0 đến 240 phút.';
    }
    final cooking = int.tryParse(draft.cookingMinutes);
    if (cooking == null || cooking < 1 || cooking > 720) {
      errors['cooking'] = 'Nhập từ 1 đến 720 phút.';
    }
    if (draft.servings < 1 || draft.servings > RecipeEditorLimits.maxServings) {
      errors['servings'] = 'Khẩu phần từ 1 đến 50 người.';
    }
    if (draft.ingredients.isEmpty ||
        draft.ingredients.length > RecipeEditorLimits.ingredients) {
      errors['ingredients'] = 'Thêm từ 1 đến 30 nguyên liệu.';
    }
    final seen = <String>{};
    for (final item in draft.ingredients) {
      if (!groupIds.contains(item.groupId)) {
        errors[ingredientError(item.id)] = 'Chọn nhóm nguyên liệu hợp lệ.';
      }
      final itemErrors = validateIngredient(item);
      if (itemErrors.isNotEmpty) {
        errors[ingredientError(item.id)] = itemErrors.values.first;
      }
      final key = item.ingredientId == null
          ? 'custom:${item.name.trim().toLowerCase()}'
          : 'catalog:${item.ingredientId}';
      if (!seen.add(key)) {
        errors[ingredientError(item.id)] = 'Nguyên liệu đã có trong danh sách.';
      }
    }
    if (draft.steps.isEmpty || draft.steps.length > RecipeEditorLimits.steps) {
      errors['steps'] = 'Thêm từ 1 đến 20 bước nấu.';
    }
    for (final item in draft.steps) {
      if (item.title.length > RecipeEditorLimits.stepTitleLength) {
        errors['stepTitle.${item.id}'] = 'Tên bước tối đa 80 ký tự.';
      }
      if (item.tip.length > RecipeEditorLimits.noteLength) {
        errors['stepTip.${item.id}'] = 'Mẹo tối đa 500 ký tự.';
      }
      if (item.minutes.isNotEmpty) {
        final minutes = int.tryParse(item.minutes);
        if (minutes == null || minutes < 1 || minutes > 720) {
          errors['stepMinutes.${item.id}'] = 'Nhập từ 1 đến 720 phút.';
        }
      }
      if (item.instruction.trim().isEmpty) {
        errors[stepInstruction(item.id)] = 'Mô tả cách thực hiện bước này.';
      } else if (item.instruction.length >
          RecipeEditorLimits.instructionLength) {
        errors[stepInstruction(item.id)] = 'Mỗi bước tối đa 2000 ký tự.';
      }
    }
    if (draft.remix != null) {
      if (draft.remix!.changes.trim().length < 10 ||
          draft.remix!.changes.length > 500) {
        errors['remixChanges'] =
            'Mô tả điều chỉnh của bạn từ 10 đến 500 ký tự.';
      }
      if (errors.isEmpty &&
          (draft.remixBaseline == null ||
              draft.contentFingerprint == draft.remixBaseline)) {
        errors['remixContent'] =
            'Hãy chỉnh sửa công thức trước khi gửi bản biến tấu.';
      }
    }
    return Map.unmodifiable(errors);
  }

  /// Stage indexes belong to the authoring flow, without UI dependencies.
  static int stageForError(String key) {
    if (key == 'remixContent') return 3;
    if (key == 'ingredients' ||
        key == 'groups' ||
        key.startsWith('group.') ||
        key.startsWith('ingredient.')) {
      return 1;
    }
    if (key == 'steps' ||
        key == 'storageNotes' ||
        key.startsWith('step.') ||
        key.startsWith('stepTitle.') ||
        key.startsWith('stepTip.') ||
        key.startsWith('stepMinutes.')) {
      return 2;
    }
    return 0;
  }
}
