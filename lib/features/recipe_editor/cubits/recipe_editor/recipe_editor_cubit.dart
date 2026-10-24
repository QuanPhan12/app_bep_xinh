import 'package:app_bep_xinh/core/utils/search_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/recipe_draft.dart';
import '../../services/recipe_cover_picker.dart';
import '../../services/recipe_editor_service.dart';
import '../../validation/recipe_editor_validation.dart';
import 'recipe_editor_state.dart';

export 'recipe_editor_state.dart';

class RecipeEditorCubit extends Cubit<RecipeEditorState> {
  final RecipeEditorService service;
  final RecipeCoverPicker coverPicker;
  Future<void>? _loadTask;
  Future<bool>? _exitTask;
  int _nextId = 1;
  int _coverRevision = 0;

  RecipeEditorCubit({required this.service, required this.coverPicker})
    : super(RecipeEditorState());

  Future<void> loadDraft() {
    if (isClosed || state.status == RecipeEditorStatus.ready) {
      return Future.value();
    }
    return _loadTask ??= _loadDraft().whenComplete(() => _loadTask = null);
  }

  Future<void> _loadDraft() async {
    emit(state.copyWith(status: RecipeEditorStatus.loading));
    try {
      final draft = await service.loadDraft() ?? RecipeDraft();
      if (isClosed) return;
      // Form chỉ được dựng sau load, tránh ghi đè dữ liệu người dùng đang nhập.
      emit(
        state.copyWith(
          status: RecipeEditorStatus.ready,
          draft: draft,
          savedDraft: draft,
        ),
      );
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          state.copyWith(
            status: RecipeEditorStatus.loadFailure,
            message: 'Không tải được bản nháp. Vui lòng thử lại.',
          ),
        );
      }
      return;
    }
    try {
      final coverRevision = _coverRevision;
      final recovered = await coverPicker.recoverLostCover();
      if (!isClosed && recovered != null && coverRevision == _coverRevision) {
        _update(state.draft.copyWith(cover: recovered));
      }
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        _notice('Không khôi phục được ảnh. Bạn có thể chọn lại.');
      }
    }
  }

  void _update(RecipeDraft draft) {
    if (isClosed ||
        state.status != RecipeEditorStatus.ready ||
        state.isSubmitting) {
      return;
    }
    emit(
      state.copyWith(
        draft: draft,
        errors: state.showErrors
            ? RecipeEditorValidation.validate(draft)
            : const {},
      ),
    );
  }

  void changeTitle(String value) => _update(state.draft.copyWith(title: value));
  void changePreparation(String value) =>
      _update(state.draft.copyWith(preparationMinutes: value));
  void changeCooking(String value) =>
      _update(state.draft.copyWith(cookingMinutes: value));
  void selectDifficulty(RecipeDifficulty value) =>
      _update(state.draft.copyWith(difficulty: value));
  void changeServings(int delta) => _update(
    state.draft.copyWith(
      servings: (state.draft.servings + delta).clamp(
        1,
        RecipeEditorLimits.maxServings,
      ),
    ),
  );
  void removeCover() {
    _coverRevision++;
    _update(state.draft.copyWith(removeCover: true));
  }

  void upsertIngredient(RecipeIngredientDraft value) {
    if (state.isSubmitting || state.status != RecipeEditorStatus.ready) return;
    final item = value.normalized();
    if (RecipeEditorValidation.validateIngredient(item).isNotEmpty) return;
    final items = state.draft.ingredients;
    final existing = items.indexWhere((row) => row.id == item.id);
    if (existing < 0 && items.length >= RecipeEditorLimits.ingredients) return;
    final duplicate = items.any(
      (row) =>
          row.id != item.id &&
          (item.ingredientId != null && row.ingredientId != null
              ? row.ingredientId == item.ingredientId
              : searchKey(row.name) == searchKey(item.name)),
    );
    if (duplicate) {
      _notice('Nguyên liệu đã có. Chạm vào dòng để sửa lượng dùng.');
      return;
    }
    if (existing >= 0) {
      final updated = [...items];
      updated[existing] = item;
      _update(state.draft.copyWith(ingredients: updated));
    } else {
      String id;
      do {
        id = 'ingredient_${_nextId++}';
      } while (items.any((row) => row.id == id));
      _update(state.draft.copyWith(ingredients: [...items, item.withId(id)]));
    }
  }

  void removeIngredient(String id) => _update(
    state.draft.copyWith(
      ingredients: state.draft.ingredients
          .where((item) => item.id != id)
          .toList(),
    ),
  );

  void changeStep(String id, String instruction) => _update(
    state.draft.copyWith(
      steps: state.draft.steps
          .map(
            (item) => item.id == id ? item.withInstruction(instruction) : item,
          )
          .toList(),
    ),
  );

  void addStep() {
    if (state.draft.steps.length >= RecipeEditorLimits.steps) return;
    String id;
    do {
      id = 'step_${_nextId++}';
    } while (state.draft.steps.any((item) => item.id == id));
    _update(
      state.draft.copyWith(
        steps: [
          ...state.draft.steps,
          RecipeStepDraft(id: id),
        ],
      ),
    );
  }

  void removeStep(String id) {
    if (state.draft.steps.length <= 1) return;
    _update(
      state.draft.copyWith(
        steps: state.draft.steps.where((item) => item.id != id).toList(),
      ),
    );
  }

  Future<void> pickCover() async {
    if (!_canOperate) return;
    _coverRevision++;
    emit(state.copyWith(operation: RecipeEditorOperation.pickingCover));
    try {
      final photo = await coverPicker.pickCover();
      if (!isClosed && photo != null) {
        _update(state.draft.copyWith(cover: photo));
      }
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        _notice(
          error is RecipeCoverException
              ? error.message
              : 'Không chọn được ảnh. Vui lòng thử lại.',
        );
      }
    } finally {
      if (!isClosed) {
        emit(state.copyWith(operation: RecipeEditorOperation.idle));
      }
    }
  }

  bool get _canOperate =>
      !isClosed && state.status == RecipeEditorStatus.ready && !state.isBusy;

  Future<void> saveDraft() async {
    if (!_canOperate || !state.hasUnsavedChanges) return;
    final snapshot = state.draft;
    emit(state.copyWith(operation: RecipeEditorOperation.savingDraft));
    try {
      await service.saveDraft(snapshot);
      if (isClosed) return;
      // Nếu người dùng tiếp tục gõ lúc lưu, phần mới vẫn được coi là chưa lưu.
      emit(state.copyWith(savedDraft: snapshot));
      _notice('Đã lưu bản nháp.');
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        _notice('Chưa lưu được bản nháp. Vui lòng thử lại.');
      }
    } finally {
      if (!isClosed) {
        emit(state.copyWith(operation: RecipeEditorOperation.idle));
      }
    }
  }

  Future<void> submit() async {
    if (!_canOperate) return;
    final errors = RecipeEditorValidation.validate(state.draft);
    emit(state.copyWith(errors: errors, showErrors: true));
    if (errors.isNotEmpty) return;
    final snapshot = state.draft.normalized();
    emit(state.copyWith(operation: RecipeEditorOperation.submitting));
    try {
      await service.submit(snapshot);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RecipeEditorStatus.submitted,
          savedDraft: state.draft,
          allowExit: true,
          operation: RecipeEditorOperation.idle,
        ),
      );
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(state.copyWith(operation: RecipeEditorOperation.idle));
        _notice('Chưa gửi được công thức. Vui lòng thử lại.');
      }
    }
  }

  void _notice(String message) =>
      emit(state.copyWith(message: message, noticeId: state.noticeId + 1));

  Future<bool> requestExit(Future<bool> Function() confirmDiscard) {
    if (isClosed || state.isBusy || _exitTask != null) {
      return Future.value(false);
    }
    return _exitTask ??= _requestExit(confirmDiscard)
        .whenComplete(() => _exitTask = null);
  }

  Future<bool> _requestExit(Future<bool> Function() confirmDiscard) async {
    final canExit = !state.hasUnsavedChanges || await confirmDiscard();
    if (isClosed || !canExit) return false;
    emit(state.copyWith(allowExit: true));
    return true;
  }
}
