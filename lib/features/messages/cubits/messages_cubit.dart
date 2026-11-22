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
  const MessagesState({
    this.items = const [],
    this.loading = true,
    this.unreadOnly = false,
    this.query = '',
    this.error,
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
  }) => MessagesState(
    items: items == null ? this.items : List.unmodifiable(items),
    loading: loading ?? this.loading,
    unreadOnly: unreadOnly ?? this.unreadOnly,
    query: query ?? this.query,
    error: error,
  );
  @override
  List<Object?> get props => [items, loading, unreadOnly, query, error];
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

  @override
  Future<void> close() async {
    _revision++;
    _initialTimeout?.cancel();
    final subscription = _subscription;
    await super.close();
    await subscription?.cancel();
  }
}
