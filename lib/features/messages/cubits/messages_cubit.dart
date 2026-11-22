import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/conversation.dart';
import '../services/message_repository.dart';

class MessagesState extends Equatable {
  final List<Conversation> items;
  final bool loading;
  final bool unreadOnly;
  final String query;
  final String? error;
  final String? deletingId;
  const MessagesState({
    this.items = const [],
    this.loading = true,
    this.unreadOnly = false,
    this.query = '',
    this.error,
    this.deletingId,
  });

  List<Conversation> get visibleItems => items
      .where(
        (item) =>
            (!unreadOnly || item.unreadCount > 0) &&
            item.name.toLowerCase().contains(query.trim().toLowerCase()),
      )
      .toList();

  MessagesState copyWith({
    List<Conversation>? items,
    bool? loading,
    bool? unreadOnly,
    String? query,
    String? error,
    String? deletingId,
    bool finishDeleting = false,
  }) => MessagesState(
    items: items == null ? this.items : List.unmodifiable(items),
    loading: loading ?? this.loading,
    unreadOnly: unreadOnly ?? this.unreadOnly,
    query: query ?? this.query,
    error: error,
    deletingId: finishDeleting ? null : deletingId ?? this.deletingId,
  );
  @override
  List<Object?> get props => [
    items,
    loading,
    unreadOnly,
    query,
    error,
    deletingId,
  ];
}

class MessagesCubit extends Cubit<MessagesState> {
  final MessageRepository repository;
  StreamSubscription<List<Conversation>>? _subscription;
  Timer? _initialTimeout;
  int _revision = 0;
  MessagesCubit(this.repository) : super(const MessagesState());
  Future<void> load() async {
    if (isClosed) return;
    final revision = ++_revision;
    _initialTimeout?.cancel();
    await _subscription?.cancel();
    if (isClosed || revision != _revision) return;
    emit(state.copyWith(loading: true));
    void fail() {
      _initialTimeout?.cancel();
      if (!isClosed && revision == _revision) {
        emit(
          state.copyWith(
            loading: false,
            error: 'Chưa tải được tin nhắn. Bạn thử lại nhé.',
          ),
        );
      }
    }

    _initialTimeout = Timer(const Duration(seconds: 20), fail);
    try {
      _subscription = repository.watchInbox().listen((items) {
        _initialTimeout?.cancel();
        if (!isClosed && revision == _revision) {
          emit(state.copyWith(items: items, loading: false));
        }
      }, onError: (Object _) => fail());
    } catch (_) {
      fail();
    }
  }

  void search(String query) {
    if (!isClosed) emit(state.copyWith(query: query));
  }

  void filterUnread(bool value) {
    if (!isClosed) emit(state.copyWith(unreadOnly: value));
  }

  Future<bool> deleteConversation(String id) async {
    if (isClosed ||
        state.deletingId != null ||
        !state.items.any((item) => item.id == id)) {
      return false;
    }
    emit(state.copyWith(deletingId: id, error: state.error));
    try {
      await repository.deleteConversation(id);
      return true;
    } catch (_) {
      return false;
    } finally {
      if (!isClosed)
        emit(state.copyWith(finishDeleting: true, error: state.error));
    }
  }

  @override
  Future<void> close() async {
    _revision++;
    _initialTimeout?.cancel();
    final subscription = _subscription;
    await super.close();
    await subscription?.cancel();
  }
}
