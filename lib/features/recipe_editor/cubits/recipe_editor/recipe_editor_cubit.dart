import 'package:app_bep_xinh/core/utils/search_utils.dart';
import 'package:app_bep_xinh/core/models/app_notification_type.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:async';

import '../../models/recipe_draft.dart';
import '../../services/recipe_cover_picker.dart';
import '../../services/recipe_editor_service.dart';
import '../../services/recipe_image_uploader.dart';
import '../../services/recipe_authoring_repository.dart';
import '../../validation/recipe_editor_validation.dart';
import 'recipe_editor_state.dart';

export 'recipe_editor_state.dart';

class RecipeEditorCubit extends Cubit<RecipeEditorState> {
  final RecipeEditorService service;
  final RecipeCoverPicker coverPicker;
  final RecipeDraft? seedDraft;
  final RecipeDraft? expectedDraft;
  Future<void>? _loadTask;
  Future<bool>? _exitTask;
  int _nextId = 1;
  int _coverRevision = 0;
  StreamSubscription<String>? _progressSubscription;

  RecipeEditorCubit({
    required this.service,
    required this.coverPicker,
    this.seedDraft,
    this.expectedDraft,
  }) : super(RecipeEditorState()) {
    final source = service;
    if (source is RecipeEditorProgressSource) {
      _progressSubscription = (source as RecipeEditorProgressSource).progress
          .listen((label) {
            if (!isClosed && state.isBusy) {
              emit(state.copyWith(workLabel: label));
            }
          });
    }
  }

  @override
  Future<void> close() async {
    await _progressSubscription?.cancel();
    await super.close();
  }

  Future<void> loadDraft() {
    if (isClosed || state.status == RecipeEditorStatus.ready) {
      return Future.value();
    }
    return _loadTask ??= _loadDraft().whenComplete(() => _loadTask = null);
  }

  Future<void> _loadDraft() async {
    emit(state.copyWith(status: RecipeEditorStatus.loading));
    try {
      final savedDraft = await service.loadDraft();
      if (seedDraft != null && savedDraft != expectedDraft) {
        throw const RecipeAuthoringException(
          'Bản nháp vừa thay đổi. Hãy quay lại và mở bản biến tấu lần nữa.',
        );
      }
      final draft = seedDraft ?? savedDraft ?? RecipeDraft();
      if (isClosed) return;
      // Form chỉ được dựng sau load, tránh ghi đè dữ liệu người dùng đang nhập.
      emit(
        state.copyWith(
          status: RecipeEditorStatus.ready,
          draft: draft,
          savedDraft: seedDraft == null ? draft : savedDraft ?? RecipeDraft(),
          hasSavedDraft: savedDraft != null,
        ),
      );
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          state.copyWith(
            status: RecipeEditorStatus.loadFailure,
            message: error is RecipeAuthoringException
                ? error.message
                : 'Không tải được bản nháp. Vui lòng thử lại.',
          ),
        );
      }
      return;
    }
    try {
      final coverRevision = _coverRevision;
      final picker = coverPicker;
      final recovered = picker is RecipePhotosPicker
          ? await (picker as RecipePhotosPicker).recoverLostPhotos()
          : <RecipeImage>[?await picker.recoverLostCover()];
      if (!isClosed &&
          recovered.isNotEmpty &&
          coverRevision == _coverRevision) {
        _appendPhotos(recovered);
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
            ? Map.fromEntries(
                RecipeEditorValidation.validate(draft).entries.where(
                  (entry) =>
                      RecipeEditorValidation.stageForError(entry.key) <=
                      state.step.index,
                ),
              )
            : const {},
      ),
    );
  }

  void changeRemixChanges(String value) {
    final remix = state.draft.remix;
    if (remix != null) {
      _update(state.draft.copyWith(remix: remix.withChanges(value)));
    }
  }

  void changeTitle(String value) => _update(state.draft.copyWith(title: value));
  void changeDescription(String value) =>
      _update(state.draft.copyWith(description: value));
  void changeStorageNotes(String value) =>
      _update(state.draft.copyWith(storageNotes: value));
  void toggleCategory(RecipeCategory category) {
    final categories = {...state.draft.categories};
    if (!categories.add(category)) categories.remove(category);
    _update(state.draft.copyWith(categories: categories));
  }

  void toggleMeal(RecipeMeal meal) {
    final meals = {...state.draft.meals};
    if (!meals.add(meal)) meals.remove(meal);
    _update(state.draft.copyWith(meals: meals));
  }

  void previousStep() {
    if (!_canOperate || state.step.index == 0) return;
    emit(
      state.copyWith(
        step: RecipeEditorStep.values[state.step.index - 1],
        errors: const {},
        showErrors: false,
      ),
    );
  }

  void nextStep() {
    if (state.step == RecipeEditorStep.review) return;
    goToStep(RecipeEditorStep.values[state.step.index + 1]);
  }

  void goToStep(RecipeEditorStep target) {
    if (!_canOperate ||
        target == state.step ||
        target.index > state.furthestStep &&
            target.index > state.step.index + 1) {
      return;
    }
    if (target.index > state.step.index) {
      final errors = RecipeEditorValidation.validate(state.draft);
      final blocking = errors.entries.where(
        (entry) =>
            RecipeEditorValidation.stageForError(entry.key) < target.index,
      );
      if (blocking.isNotEmpty) {
        final firstStage = blocking
            .map((entry) => RecipeEditorValidation.stageForError(entry.key))
            .reduce((a, b) => a < b ? a : b);
        emit(
          state.copyWith(
            errors: Map.fromEntries(blocking),
            showErrors: true,
            step: RecipeEditorStep.values[firstStage],
          ),
        );
        return;
      }
    }
    emit(
      state.copyWith(
        step: target,
        furthestStep: target.index > state.furthestStep
            ? target.index
            : state.furthestStep,
        errors: const {},
        showErrors: false,
      ),
    );
  }

  void addIngredientGroup() {
    if (!_canOperate ||
        state.draft.ingredientGroups.length >= RecipeEditorLimits.groups) {
      return;
    }
    String id;
    do {
      id = 'group_${_nextId++}';
    } while (state.draft.ingredientGroups.any((group) => group.id == id));
    _update(
      state.draft.copyWith(
        ingredientGroups: [
          ...state.draft.ingredientGroups,
          RecipeIngredientGroup(id: id, name: 'Nhóm nguyên liệu mới'),
        ],
      ),
    );
  }

  void renameIngredientGroup(String id, String name) => _update(
    state.draft.copyWith(
      ingredientGroups: state.draft.ingredientGroups
          .map(
            (group) => group.id == id
                ? RecipeIngredientGroup(id: id, name: name)
                : group,
          )
          .toList(),
    ),
  );

  void removeIngredientGroup(String id) {
    if (!_canOperate || state.draft.ingredientGroups.length <= 1) return;
    final groups = state.draft.ingredientGroups
        .where((group) => group.id != id)
        .toList();
    _update(
      state.draft.copyWith(
        ingredientGroups: groups,
        ingredients: state.draft.ingredients
            .map(
              (item) =>
                  item.groupId == id ? item.inGroup(groups.first.id) : item,
            )
            .toList(),
      ),
    );
  }

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
    final photos = state.draft.photos;
    _update(
      state.draft.copyWith(
        cover: photos.firstOrNull,
        removeCover: photos.isEmpty,
        photos: photos.skip(1).toList(),
      ),
    );
  }

  void removePhoto(String id) {
    if (!_canOperate) return;
    _coverRevision++;
    _update(
      state.draft.copyWith(
        photos: state.draft.photos.where((image) => image.id != id).toList(),
      ),
    );
  }

  void makeCover(String id) {
    if (!_canOperate) return;
    final photo = state.draft.photos
        .where((image) => image.id == id)
        .firstOrNull;
    if (photo == null) return;
    _coverRevision++;
    _update(
      state.draft.copyWith(
        cover: photo,
        photos: [
          if (state.draft.cover != null) state.draft.cover!,
          ...state.draft.photos.where((image) => image.id != id),
        ],
      ),
    );
  }

  void _appendPhotos(List<RecipeImage> images) {
    final all = [
      if (state.draft.cover != null) state.draft.cover!,
      ...state.draft.photos,
    ];
    final ids = all.map((image) => image.id).toSet();
    final incoming = images.where((image) => ids.add(image.id)).toList();
    if (all.length + incoming.length > RecipeEditorLimits.maxPostPhotos) {
      _notice('Mỗi bài đăng có tối đa 10 ảnh.');
      return;
    }
    all.addAll(incoming);
    if (all.isEmpty) return;
    _update(
      state.draft.copyWith(cover: all.first, photos: all.skip(1).toList()),
    );
  }

  Future<void> addPhotos() async {
    if (!_canOperate) return;
    final remaining =
        RecipeEditorLimits.maxPostPhotos -
        state.draft.photos.length -
        (state.draft.cover == null ? 0 : 1);
    if (remaining <= 0) {
      _notice('Mỗi bài đăng có tối đa 10 ảnh.');
      return;
    }
    _coverRevision++;
    emit(state.copyWith(operation: RecipeEditorOperation.pickingCover));
    try {
      final picker = coverPicker;
      final photos = picker is RecipePhotosPicker
          ? await (picker as RecipePhotosPicker).pickPhotos(remaining)
          : <RecipeImage>[?await picker.pickCover()];
      if (!isClosed) _appendPhotos(photos);
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

  void upsertIngredient(RecipeIngredientDraft value, {String? groupId}) {
    if (state.isSubmitting || state.status != RecipeEditorStatus.ready) return;
    final item = (groupId == null ? value : value.inGroup(groupId))
        .normalized();
    if (!state.draft.ingredientGroups.any(
      (group) => group.id == item.groupId,
    )) {
      return;
    }
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
      _notice(
        'Nguyên liệu đã có. Chạm vào dòng để sửa lượng dùng.',
        type: AppNotificationType.warning,
      );
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

  void updateStep(
    String id, {
    String? title,
    String? minutes,
    String? tip,
    RecipeCover? photo,
    bool removePhoto = false,
  }) => _update(
    state.draft.copyWith(
      steps: state.draft.steps
          .map(
            (item) => item.id == id
                ? item.copyWith(
                    title: title,
                    minutes: minutes,
                    tip: tip,
                    photo: photo,
                    removePhoto: removePhoto,
                  )
                : item,
          )
          .toList(),
    ),
  );

  void moveStep(String id, int offset) {
    if (!_canOperate) return;
    final items = [...state.draft.steps];
    final index = items.indexWhere((item) => item.id == id);
    final target = index + offset;
    if (index < 0 || target < 0 || target >= items.length) return;
    items.insert(target, items.removeAt(index));
    _update(state.draft.copyWith(steps: items));
  }

  Future<void> pickStepPhoto(String id, {bool camera = false}) async {
    if (!_canOperate || !state.draft.steps.any((step) => step.id == id)) return;
    emit(state.copyWith(operation: RecipeEditorOperation.pickingStepPhoto));
    try {
      final photo = await _pickPhoto(camera);
      if (!isClosed && photo != null) updateStep(id, photo: photo);
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

  Future<RecipeCover?> _pickPhoto(bool camera) {
    if (!camera) return coverPicker.pickCover();
    final picker = coverPicker;
    if (picker is CameraRecipeCoverPicker) {
      return (picker as CameraRecipeCoverPicker).captureCover();
    }
    throw const RecipeCoverException(
      'Thiết bị chưa hỗ trợ chụp ảnh. Hãy chọn ảnh từ thư viện.',
    );
  }

  Future<void> pickCover({bool camera = false}) async {
    if (!_canOperate) return;
    _coverRevision++;
    emit(state.copyWith(operation: RecipeEditorOperation.pickingCover));
    try {
      final photo = await _pickPhoto(camera);
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
      emit(state.copyWith(savedDraft: snapshot, hasSavedDraft: true));
      _notice('Đã lưu bản nháp.', type: AppNotificationType.success);
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        _notice(
          error is RecipeUploadException
              ? error.message
              : error is RecipeAuthoringException
              ? error.message
              : 'Chưa lưu được bản nháp. Vui lòng thử lại.',
        );
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
    if (errors.isNotEmpty) {
      final index = errors.keys
          .map(RecipeEditorValidation.stageForError)
          .reduce((a, b) => a < b ? a : b);
      emit(state.copyWith(step: RecipeEditorStep.values[index]));
      return;
    }
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
        _notice(
          error is RecipeUploadException
              ? error.message
              : error is RecipeAuthoringException
              ? error.message
              : 'Chưa gửi được công thức. Vui lòng thử lại.',
        );
      }
    }
  }

  void _notice(
    String message, {
    AppNotificationType type = AppNotificationType.error,
  }) => emit(
    state.copyWith(
      message: message,
      noticeType: type,
      noticeId: state.noticeId + 1,
    ),
  );

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
