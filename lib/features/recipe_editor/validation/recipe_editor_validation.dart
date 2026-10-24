import '../models/recipe_draft.dart';

class RecipeEditorLimits {
  const RecipeEditorLimits._();
  static const titleLength = 80;
  static const ingredientNameLength = 80;
  static const ingredientNoteLength = 160;
  static const maxIngredientAmount = 100000;
  static const instructionLength = 2000;
  static const ingredients = 30;
  static const steps = 20;
  static const maxServings = 50;
  static const maxCoverBytes = 8 * 1024 * 1024;
}

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
          amount > RecipeEditorLimits.maxIngredientAmount) {
        errors['amount'] = 'Nhập lượng dùng lớn hơn 0, tối đa 100.000.';
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
      if (item.instruction.trim().isEmpty) {
        errors[stepInstruction(item.id)] = 'Mô tả cách thực hiện bước này.';
      } else if (item.instruction.length >
          RecipeEditorLimits.instructionLength) {
        errors[stepInstruction(item.id)] = 'Mỗi bước tối đa 2000 ký tự.';
      }
    }
    return Map.unmodifiable(errors);
  }
}
