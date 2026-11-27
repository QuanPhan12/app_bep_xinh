import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/recipe_search_request.dart';

/// Sheet giữ bản lựa chọn riêng; chỉ Áp dụng mới thay đổi kết quả ở màn chính.
class RecipeSearchFilterCubit extends Cubit<RecipeSearchRequest> {
  RecipeSearchFilterCubit(super.initialState);
  void selectMinutes(int? minutes) =>
      emit(state.copyWith(maxMinutes: minutes, clearMinutes: minutes == null));
  void selectDifficulty(RecipeDifficulty? difficulty) => emit(
    state.copyWith(difficulty: difficulty, clearDifficulty: difficulty == null),
  );
  void changeExcluded(String text) =>
      emit(state.copyWith(excludedIngredients: text));
  void reset() =>
      emit(RecipeSearchRequest(query: state.query, filter: state.filter));
}
