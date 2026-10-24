import 'package:equatable/equatable.dart';

import '../../models/recipe_draft.dart';

enum RecipeEditorStatus { initial, loading, ready, loadFailure, submitted }

enum RecipeEditorOperation { idle, pickingCover, savingDraft, submitting }

class RecipeEditorState extends Equatable {
  final RecipeEditorStatus status;
  final RecipeEditorOperation operation;
  final RecipeDraft draft;
  final RecipeDraft savedDraft;
  final Map<String, String> errors;
  final bool showErrors;
  final String? message;
  final int noticeId;
  final bool allowExit;

  RecipeEditorState({
    this.status = RecipeEditorStatus.initial,
    this.operation = RecipeEditorOperation.idle,
    RecipeDraft? draft,
    RecipeDraft? savedDraft,
    Map<String, String> errors = const {},
    this.showErrors = false,
    this.message,
    this.noticeId = 0,
    this.allowExit = false,
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
    bool? allowExit,
  }) => RecipeEditorState(
    status: status ?? this.status,
    operation: operation ?? this.operation,
    draft: draft ?? this.draft,
    savedDraft: savedDraft ?? this.savedDraft,
    errors: errors ?? this.errors,
    showErrors: showErrors ?? this.showErrors,
    message: message ?? this.message,
    noticeId: noticeId ?? this.noticeId,
    allowExit: allowExit ?? this.allowExit,
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
    allowExit,
  ];
}
