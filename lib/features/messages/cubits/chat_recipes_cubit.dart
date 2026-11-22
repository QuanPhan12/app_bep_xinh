import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/search_utils.dart';
import '../models/chat_recipe.dart';
import '../services/message_repository.dart';

class ChatRecipesState extends Equatable {
  const ChatRecipesState({
    this.items = const [],
    this.query = '',
    this.loading = true,
    this.error,
  });
  final List<ChatRecipe> items;
  final String query;
  final bool loading;
  final String? error;
  List<ChatRecipe> get visible => items
      .where((r) => searchKey(r.title).contains(searchKey(query)))
      .toList();
  @override
  List<Object?> get props => [items, query, loading, error];
}

class ChatRecipesCubit extends Cubit<ChatRecipesState> {
  ChatRecipesCubit(this.repository) : super(const ChatRecipesState());
  final MessageRepository repository;
  bool _loading = false;
  Future<void> load() async {
    if (isClosed || _loading) return;
    _loading = true;
    emit(ChatRecipesState(items: state.items, query: state.query));
    try {
      final items = await repository.loadRecipes().timeout(
        const Duration(seconds: 20),
      );
      if (!isClosed) {
        emit(
          ChatRecipesState(
            items: List.unmodifiable(items),
            query: state.query,
            loading: false,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          ChatRecipesState(
            items: state.items,
            query: state.query,
            loading: false,
            error: 'Chưa tải được công thức. Vui lòng thử lại.',
          ),
        );
      }
    } finally {
      _loading = false;
    }
  }

  void search(String value) {
    if (!isClosed) {
      emit(
        ChatRecipesState(
          items: state.items,
          query: value,
          loading: state.loading,
          error: state.error,
        ),
      );
    }
  }
}
