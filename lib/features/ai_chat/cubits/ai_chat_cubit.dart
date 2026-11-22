import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/ai_message.dart';
import '../services/ai_chat_repository.dart';

class AiChatState {
  final List<AiMessage> messages;
  final String draft;
  final bool loading, sending, loadFailed;
  final String? error;
  const AiChatState({
    this.messages = const [],
    this.draft = '',
    this.loading = true,
    this.sending = false,
    this.loadFailed = false,
    this.error,
  });
  AiChatState copy({
    List<AiMessage>? messages,
    String? draft,
    bool? loading,
    bool? sending,
    bool? loadFailed,
    String? error,
  }) => AiChatState(
    messages: messages ?? this.messages,
    draft: draft ?? this.draft,
    loading: loading ?? this.loading,
    sending: sending ?? this.sending,
    loadFailed: loadFailed ?? this.loadFailed,
    error: error,
  );
}

class AiChatCubit extends Cubit<AiChatState> {
  final AiChatRepository repository;
  String? _requestId;
  bool _loading = false;
  bool _hasLoaded = false;
  AiChatCubit(this.repository) : super(const AiChatState());
  Future<void> ensureLoaded() async {
    if (!_hasLoaded) await load();
  }

  Future<void> load() async {
    if (isClosed || _loading || state.sending) return;
    _loading = true;
    emit(state.copy(loading: true));
    try {
      final items = await repository.history();
      if (!isClosed) {
        _hasLoaded = true;
        emit(
          state.copy(
            messages: List.unmodifiable(items),
            loading: false,
            loadFailed: false,
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
