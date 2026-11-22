import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/ai_message.dart';
import '../../messages/models/chat_history_page.dart';
import '../services/ai_chat_repository.dart';

class AiChatState {
  final List<AiMessage> messages;
  final String draft;
  final bool loading, sending, loadFailed;
  final bool hasOlder, loadingOlder, olderLoadFailed;
  final String? error;
  const AiChatState({
    this.messages = const [],
    this.draft = '',
    this.loading = true,
    this.sending = false,
    this.loadFailed = false,
    this.hasOlder = false,
    this.loadingOlder = false,
    this.olderLoadFailed = false,
    this.error,
  });
  AiChatState copy({
    List<AiMessage>? messages,
    String? draft,
    bool? loading,
    bool? sending,
    bool? loadFailed,
    bool? hasOlder,
    bool? loadingOlder,
    bool? olderLoadFailed,
    String? error,
  }) => AiChatState(
    messages: messages ?? this.messages,
    draft: draft ?? this.draft,
    loading: loading ?? this.loading,
    sending: sending ?? this.sending,
    loadFailed: loadFailed ?? this.loadFailed,
    hasOlder: hasOlder ?? this.hasOlder,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    olderLoadFailed: olderLoadFailed ?? this.olderLoadFailed,
    error: error,
  );
}

class AiChatCubit extends Cubit<AiChatState> {
  final AiChatRepository repository;
  String? _requestId;
  bool _loading = false;
  bool _hasLoaded = false;
  LoadOlderMessages<AiMessage>? _loadOlder;
  AiChatCubit(this.repository) : super(const AiChatState());
  Future<void> ensureLoaded() async {
    if (!_hasLoaded) await load();
  }

  Future<void> load() async {
    if (isClosed || _loading || state.sending || state.loadingOlder) return;
    _loading = true;
    emit(state.copy(loading: true));
    try {
      final page = await repository.history();
      if (!isClosed) {
        _hasLoaded = true;
        _loadOlder = page.loadOlder;
        emit(
          state.copy(
            messages: List.unmodifiable(page.messages),
            loading: false,
            loadFailed: false,
            hasOlder: _loadOlder != null,
            olderLoadFailed: false,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copy(
            loading: false,
            loadFailed: true,
            error: error is AiChatFailure
                ? error.message
                : 'Chưa tải được hội thoại AI.',
          ),
        );
      }
    } finally {
      _loading = false;
    }
  }

  Future<void> loadOlder() async {
    final fetch = _loadOlder;
    if (isClosed ||
        state.loading ||
        state.loadFailed ||
        state.loadingOlder ||
        fetch == null) {
      return;
    }
    emit(
      state.copy(
        loadingOlder: true,
        olderLoadFailed: false,
        error: state.error,
      ),
    );
    try {
      final page = await fetch();
      if (isClosed) return;
      final ids = state.messages.map((message) => message.id).toSet();
      _loadOlder = page.loadOlder;
      emit(
        state.copy(
          messages: List.unmodifiable([
            ...page.messages.where((message) => ids.add(message.id)),
            ...state.messages,
          ]),
          loadingOlder: false,
          hasOlder: _loadOlder != null,
          error: state.error,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copy(
            loadingOlder: false,
            olderLoadFailed: true,
            error: state.error,
          ),
        );
      }
    }
  }

  void change(String text) {
    if (isClosed || state.sending) return;
    if (text != state.draft) _requestId = null;
    emit(state.copy(draft: text));
  }

  Future<void> send() async {
    if (isClosed ||
        state.loading ||
        state.loadFailed ||
        state.sending ||
        state.draft.trim().isEmpty) {
      return;
    }
    if (state.draft.trim().length > 2000) {
      emit(state.copy(error: 'Tin nhắn tối đa 2.000 ký tự.'));
      return;
    }
    _requestId ??= List.generate(
      16,
      (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    emit(state.copy(sending: true));
    try {
      final response = await repository.send(state.draft.trim(), _requestId!);
      if (!isClosed) {
        final ids = response.map((m) => m.id).toSet();
        final items = [
          ...state.messages.where((m) => !ids.contains(m.id)),
          ...response,
        ];
        _requestId = null;
        emit(
          state.copy(
            messages: List.unmodifiable(items),
            draft: '',
            sending: false,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copy(
            sending: false,
            error: error is AiChatFailure
                ? error.message
                : 'Chưa gửi được tin nhắn. Vui lòng thử lại.',
          ),
        );
      }
    }
  }
}
