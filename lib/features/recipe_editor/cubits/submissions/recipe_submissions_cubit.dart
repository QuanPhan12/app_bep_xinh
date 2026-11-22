import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/recipe_submission.dart';
import '../../services/recipe_submission_service.dart';
import '../../services/recipe_authoring_repository.dart';

class RecipeSubmissionsState extends Equatable {
  final bool loading;
  final List<RecipeSubmission> items;
  final String? error;
  final bool editing;
  final int editorRequest;
  const RecipeSubmissionsState({
    this.loading = true,
    this.items = const [],
    this.error,
    this.editing = false,
    this.editorRequest = 0,
  });
  @override
  List<Object?> get props => [loading, items, error, editing, editorRequest];
}

class RecipeSubmissionsCubit extends Cubit<RecipeSubmissionsState> {
  final RecipeSubmissionService service;
  Future<void>? _task;
  RecipeSubmissionsCubit(this.service) : super(const RecipeSubmissionsState());
  Future<void> load() => state.editing
      ? Future.value()
      : _task ??= _load().whenComplete(() => _task = null);
  Future<void> createRevision(String id) async {
    if (isClosed || state.editing || state.loading) return;
    emit(
      RecipeSubmissionsState(
        loading: false,
        items: state.items,
        editing: true,
        editorRequest: state.editorRequest,
      ),
    );
    try {
      await service.createRevision(id);
      if (!isClosed) {
        emit(
          RecipeSubmissionsState(
            loading: false,
            items: state.items,
            editorRequest: state.editorRequest + 1,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          RecipeSubmissionsState(
            loading: false,
            items: state.items,
            editorRequest: state.editorRequest,
            error: error is RecipeAuthoringException
                ? error.message
                : 'Không mở được bản sửa. Vui lòng thử lại.',
          ),
        );
      }
    }
  }

  Future<void> changeVisibility(
    RecipeSubmission item,
    RecipeVisibilityAction action,
  ) async {
    if (isClosed || state.editing || state.loading) return;
    emit(
      RecipeSubmissionsState(
        loading: false,
        items: state.items,
        editing: true,
        editorRequest: state.editorRequest,
      ),
    );
    try {
      await service.changeVisibility(item, action);
      final items = await service.fetchOwn();
      if (!isClosed) {
        emit(
          RecipeSubmissionsState(
            loading: false,
            items: List.unmodifiable(items),
            editorRequest: state.editorRequest,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          RecipeSubmissionsState(
            loading: false,
            items: state.items,
            editorRequest: state.editorRequest,
            error: error is RecipeAuthoringException
                ? error.message
                : 'Không cập nhật được bài. Vui lòng tải lại và thử lại.',
          ),
        );
      }
    }
  }

  Future<void> _load() async {
    if (isClosed) return;
    emit(RecipeSubmissionsState(loading: true, items: state.items));
    try {
      final items = await service.fetchOwn();
      if (!isClosed) {
        emit(
          RecipeSubmissionsState(
            loading: false,
            items: List.unmodifiable(items),
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          RecipeSubmissionsState(
            loading: false,
            items: state.items,
            error: 'Không tải được bài đã gửi. Vui lòng thử lại.',
          ),
        );
      }
    }
  }
}
