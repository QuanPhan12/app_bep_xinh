import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/models/app_notification_type.dart';

import '../../models/recipe_draft.dart';

enum RecipeEditorStatus { initial, loading, ready, loadFailure, submitted }

enum RecipeEditorOperation {
  idle,
  pickingCover,
  pickingStepPhoto,
  savingDraft,
  submitting,
}

enum RecipeEditorStep { details, ingredients, instructions, review }

class RecipeEditorState extends Equatable {
  final RecipeEditorStatus status;
  final RecipeEditorOperation operation;
  final RecipeDraft draft;
  final RecipeDraft savedDraft;
  final Map<String, String> errors;
  final bool showErrors;
  final String? message;
  final int noticeId;
  final AppNotificationType noticeType;
  final bool allowExit;
  final RecipeEditorStep step;
  final int furthestStep;
  final bool hasSavedDraft;
  final String workLabel;

  RecipeEditorState({
    this.status = RecipeEditorStatus.initial,
    this.operation = RecipeEditorOperation.idle,
    RecipeDraft? draft,
    RecipeDraft? savedDraft,
    Map<String, String> errors = const {},
    this.showErrors = false,
    this.message,
    this.noticeId = 0,
    this.noticeType = AppNotificationType.info,
    this.allowExit = false,
    this.step = RecipeEditorStep.details,
    this.furthestStep = 0,
    this.hasSavedDraft = false,
    this.workLabel = '',
  }) : draft = draft ?? RecipeDraft(),
       savedDraft = savedDraft ?? RecipeDraft(),
       errors = Map.unmodifiable(errors);

  bool get isBusy => operation != RecipeEditorOperation.idle;
  bool get isSubmitting => operation == RecipeEditorOperation.submitting;
  bool get hasUnsavedChanges => draft != savedDraft;
  bool get canLeave => allowExit || (!isBusy && !hasUnsavedChanges);

  RecipeEditorState copyWith({
    RecipeEditorStatus? status,
    RecipeEditorOperation? operation,
    RecipeDraft? draft,
    RecipeDraft? savedDraft,
    Map<String, String>? errors,
    bool? showErrors,
    String? message,
    int? noticeId,
    AppNotificationType? noticeType,
    bool? allowExit,
    RecipeEditorStep? step,
    int? furthestStep,
    bool? hasSavedDraft,
    String? workLabel,
  }) => RecipeEditorState(
    status: status ?? this.status,
    operation: operation ?? this.operation,
    draft: draft ?? this.draft,
    savedDraft: savedDraft ?? this.savedDraft,
    errors: errors ?? this.errors,
    showErrors: showErrors ?? this.showErrors,
    message: message ?? this.message,
    noticeId: noticeId ?? this.noticeId,
    noticeType: noticeType ?? this.noticeType,
    allowExit: allowExit ?? this.allowExit,
    step: step ?? this.step,
    furthestStep: furthestStep ?? this.furthestStep,
    hasSavedDraft: hasSavedDraft ?? this.hasSavedDraft,
    workLabel: workLabel ?? (operation != null ? '' : this.workLabel),
  );

  @override
  List<Object?> get props => [
    status,
    operation,
    draft,
    savedDraft,
    errors,
    showErrors,
    message,
    noticeId,
    noticeType,
    allowExit,
    step,
    furthestStep,
    hasSavedDraft,
    workLabel,
  ];
}
