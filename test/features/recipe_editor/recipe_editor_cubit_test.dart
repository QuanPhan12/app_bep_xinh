import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';

import 'dart:async';

import 'package:app_bep_xinh/features/recipe_editor/cubits/recipe_editor/recipe_editor_cubit.dart';
import 'package:app_bep_xinh/features/recipe_editor/models/recipe_draft.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_cover_picker.dart';
import 'package:app_bep_xinh/features/recipe_editor/validation/recipe_editor_validation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/recipe_editor_fakes.dart';

void main() {
  late StubRecipeEditorService service;
  late StubRecipeCoverPicker picker;
  late RecipeEditorCubit cubit;
  setUp(() {
    service = StubRecipeEditorService();
    picker = StubRecipeCoverPicker();
    cubit = RecipeEditorCubit(service: service, coverPicker: picker);
  });
  tearDown(() => cubit.close());

  test(
    'load is deduplicated, failure retries and restores saved draft',
    () async {
      final pending = Completer<RecipeDraft?>();
      service.onLoad = () => pending.future;
      final loading = cubit.loadDraft();
      expect(identical(loading, cubit.loadDraft()), isTrue);
      expect(service.loadCalls, 1);
      pending.completeError(StateError('offline'));
      await loading;
      expect(cubit.state.status, RecipeEditorStatus.loadFailure);
      service.onLoad = null;
      service.saved = validRecipeDraft();
      await cubit.loadDraft();
      expect(cubit.state.draft, service.saved);
      expect(cubit.state.hasUnsavedChanges, isFalse);
    },
  );

  test('invalid form is not sent; validation clears when typing, clearing and retyping', () async {
    await cubit.loadDraft();
    await cubit.submit();
    expect(service.submitCalls, 0);
    expect(cubit.state.errors.keys, containsAll(['title', 'cover']));
    cubit.changeTitle('Trứng chiên');
    expect(cubit.state.errors['title'], isNull);
    cubit.changeTitle('');
    expect(cubit.state.errors['title'], isNotNull);
    cubit.changeTitle('Canh trứng');
    expect(cubit.state.draft.title, 'Canh trứng');
    expect(cubit.state.errors['title'], isNull);
    cubit.changeCooking('0');
    expect(cubit.state.errors['cooking'], isNotNull);
    cubit.changeCooking('10');
    expect(cubit.state.errors['cooking'], isNull);
  });

  test(
    'dynamic row ids retain data when removing another row and honor bounds',
    () async {
      await cubit.loadDraft();
      cubit.upsertIngredient(validRecipeDraft().ingredients.first.withId(''));
      cubit.upsertIngredient(
        const RecipeIngredientDraft(
          id: '',
          name: 'Cà chua',
          amount: 2,
          unit: IngredientUnit(id: 'fruit', label: 'quả'),
        ),
      );
      final rows = cubit.state.draft.ingredients;
      cubit.removeIngredient(rows.first.id);
      expect(cubit.state.draft.ingredients.first.name, 'Cà chua');
      cubit.upsertIngredient(
        const RecipeIngredientDraft(id: '', name: 'Nấm', toTaste: true),
      );
      expect(
        cubit.state.draft.ingredients.map((item) => item.id).toSet().length,
        2,
      );
      for (var i = 0; i < RecipeEditorLimits.ingredients + 2; i++) {
        cubit.upsertIngredient(
          RecipeIngredientDraft(id: '', name: 'Nguyên liệu $i', toTaste: true),
        );
      }
      expect(
        cubit.state.draft.ingredients.length,
        RecipeEditorLimits.ingredients,
      );
      cubit.addStep();
      final step = cubit.state.draft.steps.last.id;
      cubit.changeStep(step, 'Nấu chín.');
      cubit.removeStep(cubit.state.draft.steps.first.id);
      expect(cubit.state.draft.steps.single.instruction, 'Nấu chín.');
      cubit.removeStep(step);
      expect(cubit.state.draft.steps.length, 1);
      cubit.changeServings(100);
      expect(cubit.state.draft.servings, RecipeEditorLimits.maxServings);
      cubit.changeServings(-100);
      expect(cubit.state.draft.servings, 1);
    },
  );

  test('draft saves partially; edits during save remain dirty and duplicate write is blocked', () async {
    await cubit.loadDraft();
    cubit.changeTitle('Bản nháp');
    final pending = Completer<void>();
    service.onSave = (_) => pending.future;
    final saving = cubit.saveDraft();
    await cubit.saveDraft();
    cubit.changeTitle('Bản nháp mới');
    pending.complete();
    await saving;
    expect(service.saveCalls, 1);
    expect(service.saved!.title, 'Bản nháp');
    expect(cubit.state.draft.title, 'Bản nháp mới');
    expect(cubit.state.hasUnsavedChanges, isTrue);
    service.onSave = null;
    await cubit.saveDraft();
    expect(cubit.state.hasUnsavedChanges, isFalse);
  });

  test(
    'valid submit is normalized, blocks edits and can retry a service failure',
    () async {
      service.saved = validRecipeDraft().copyWith(title: '  Trứng chiên  ');
      await cubit.loadDraft();
      service.onSubmit = (_) => Future.error(StateError('offline'));
      await cubit.submit();
      expect(cubit.state.status, RecipeEditorStatus.ready);
      expect(cubit.state.isBusy, isFalse);
      expect(cubit.state.message, contains('Chưa gửi'));
      final pending = Completer<void>();
      service.onSubmit = (_) => pending.future;
      final submitting = cubit.submit();
      await cubit.submit();
      cubit.changeTitle('Must not overwrite');
      expect(cubit.state.draft.title, '  Trứng chiên  ');
      pending.complete();
      await submitting;
      expect(service.submitCalls, 2);
      expect(service.submitted!.title, 'Trứng chiên');
      expect(cubit.state.status, RecipeEditorStatus.submitted);
      expect(cubit.state.canLeave, isTrue);
    },
  );

  test('canceling image keeps cover, errors release busy state and late recovery cannot overwrite selection', () async {
    final recovery = Completer<RecipeCover?>();
    picker.onRecover = () => recovery.future;
    final loading = cubit.loadDraft();
    await Future<void>.value();
    picker.onPick = () async => recipeCoverFixture(id: 'chosen');
    await cubit.pickCover();
    recovery.complete(recipeCoverFixture(id: 'old'));
    await loading;
    expect(cubit.state.draft.cover!.id, 'chosen');
    picker.onPick = null;
    await cubit.pickCover();
    expect(cubit.state.draft.cover!.id, 'chosen');
    picker.onPick = () =>
        Future.error(const RecipeCoverException('Ảnh quá lớn.'));
    await cubit.pickCover();
    expect(cubit.state.message, 'Ảnh quá lớn.');
    expect(cubit.state.isBusy, isFalse);
  });

  test('unsaved exit prompts once and canceled exit preserves input', () async {
    await cubit.loadDraft();
    cubit.changeTitle('Món mới');
    final decision = Completer<bool>();
    var prompts = 0;
    final leaving = cubit.requestExit(() {
      prompts++;
      return decision.future;
    });
    expect(await cubit.requestExit(() async => true), isFalse);
    decision.complete(false);
    expect(await leaving, isFalse);
    expect(prompts, 1);
    expect(cubit.state.canLeave, isFalse);
    expect(cubit.state.draft.title, 'Món mới');
    expect(await cubit.requestExit(() async => true), isTrue);
    expect(cubit.state.canLeave, isTrue);
  });

  test('in-flight load does not emit after Cubit closes', () async {
    final pending = Completer<RecipeDraft?>();
    service.onLoad = () => pending.future;
    final loading = cubit.loadDraft();
    await cubit.close();
    pending.complete(validRecipeDraft());
    await expectLater(loading, completes);
  });
}
