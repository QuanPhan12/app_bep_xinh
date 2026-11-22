import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/recipe_report_repository.dart';

class RecipeReportState {
  final bool loading, busy;
  final OwnRecipeReport? report;
  final String? error;
  const RecipeReportState({
    this.loading = false,
    this.busy = false,
    this.report,
    this.error,
  });
}

class RecipeReportCubit extends Cubit<RecipeReportState> {
  final RecipeReportRepository repository;
  final String recipeId;
  RecipeReportCubit(this.repository, this.recipeId)
    : super(const RecipeReportState(loading: true));
  Future<void> load() async {
    if (state.busy || isClosed) return;
    emit(const RecipeReportState(loading: true, busy: true));
    try {
      final report = await repository.own(recipeId);
      if (!isClosed) emit(RecipeReportState(report: report));
    } catch (_) {
      if (!isClosed) {
        emit(
          const RecipeReportState(
            error: 'Không kiểm tra được báo cáo. Vui lòng thử lại.',
          ),
        );
      }
    }
  }

  Future<void> submit(String category, String reason) async {
    if (isClosed || state.busy || state.loading || state.report != null) return;
    emit(const RecipeReportState(busy: true));
    try {
      await repository.submit(recipeId, category, reason);
      if (!isClosed) {
        emit(const RecipeReportState(report: OwnRecipeReport('open')));
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          RecipeReportState(
            error: error is FormatException
                ? error.message
                : 'Chưa gửi được báo cáo. Kiểm tra kết nối và thử lại.',
          ),
        );
      }
    }
  }
}
