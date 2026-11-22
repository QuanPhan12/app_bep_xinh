import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/conversation.dart';
import '../services/message_repository.dart';

class RecipientsState extends Equatable {
  final List<MessageRecipient> items;
  final String query;
  final bool loading;
  final bool opening;
  final String? openingRecipientId;
  final String? error;
  const RecipientsState({
    this.items = const [],
    this.query = '',
    this.loading = true,
    this.opening = false,
    this.openingRecipientId,
    this.error,
  });
  List<MessageRecipient> get visibleItems => items
      .where(
        (item) => item.name.toLowerCase().contains(query.trim().toLowerCase()),
      )
      .toList();
  RecipientsState copyWith({
    List<MessageRecipient>? items,
    String? query,
    bool? loading,
    bool? opening,
    String? openingRecipientId,
    String? error,
  }) => RecipientsState(
    items: items == null ? this.items : List.unmodifiable(items),
    query: query ?? this.query,
    loading: loading ?? this.loading,
    opening: opening ?? this.opening,
    openingRecipientId: opening == false
        ? null
        : openingRecipientId ?? this.openingRecipientId,
    error: error,
  );
  @override
  List<Object?> get props => [
    items,
    query,
    loading,
    opening,
    openingRecipientId,
    error,
  ];
}

class RecipientsCubit extends Cubit<RecipientsState> {
  final MessageRepository repository;
  bool _loading = false;
  RecipientsCubit(this.repository) : super(const RecipientsState());
  Future<void> load() async {
    if (isClosed || _loading) return;
    _loading = true;
    emit(state.copyWith(loading: true));
    try {
      final people = await repository.loadRecipients().timeout(
        const Duration(seconds: 20),
      );
      if (!isClosed) emit(state.copyWith(items: people, loading: false));
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            loading: false,
            error: 'Chưa tải được người nhận. Vui lòng thử lại.',
          ),
        );
      }
    } finally {
      _loading = false;
    }
  }

  void search(String query) {
    if (!isClosed) emit(state.copyWith(query: query));
  }

  Future<String?> start(MessageRecipient person) async {
    if (isClosed || state.opening) return null;
    emit(state.copyWith(opening: true, openingRecipientId: person.id));
    try {
      final id = await repository
          .startConversation(person)
          .timeout(const Duration(seconds: 25));
      if (isClosed) return null;
      emit(state.copyWith(opening: false));
      return id;
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            opening: false,
            error: 'Chưa tạo được cuộc trò chuyện. Bạn thử lại nhé.',
          ),
        );
      }
      return null;
    }
  }
}
