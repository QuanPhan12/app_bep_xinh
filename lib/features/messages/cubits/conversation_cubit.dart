import '../models/chat_recipe.dart';

import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/conversation.dart';
import '../services/message_repository.dart';
import '../services/chat_image_service.dart';
import '../../recipes/models/recipe_image.dart';

class ConversationState extends Equatable {
  final Conversation? conversation;
  final bool loading;
  final bool sending;
  final String draft;
  final String? error;
  final RecipeImage? image;
  final ChatRecipe? recipe;
  final bool pickingRecipe;
  final bool pickingImage;
  final bool uploadingImage;
  const ConversationState({
    this.conversation,
    this.loading = true,
    this.sending = false,
    this.draft = '',
    this.error,
    this.image,
    this.recipe,
    this.pickingRecipe = false,
    this.pickingImage = false,
    this.uploadingImage = false,
  });
  bool get canSend =>
      !loading &&
      !sending &&
      !pickingImage &&
      !pickingRecipe &&
      conversation != null &&
      (draft.trim().isNotEmpty || image != null || recipe != null) &&
      draft.trim().length <= 2000;
  ConversationState copyWith({
    Conversation? conversation,
    bool? loading,
    bool? sending,
    String? draft,
    String? error,
    RecipeImage? image,
    ChatRecipe? recipe,
    bool clearRecipe = false,
    bool? pickingRecipe,
    bool clearImage = false,
    bool? pickingImage,
    bool? uploadingImage,
  }) => ConversationState(
    conversation: conversation ?? this.conversation,
    loading: loading ?? this.loading,
    sending: sending ?? this.sending,
    draft: draft ?? this.draft,
    error: error,
    image: clearImage ? null : image ?? this.image,
    recipe: clearRecipe ? null : recipe ?? this.recipe,
    pickingRecipe: pickingRecipe ?? this.pickingRecipe,
    pickingImage: pickingImage ?? this.pickingImage,
    uploadingImage: uploadingImage ?? this.uploadingImage,
  );
  @override
  List<Object?> get props => [
    conversation,
    loading,
    sending,
    draft,
    error,
    image,
    recipe,
    pickingRecipe,
    pickingImage,
    uploadingImage,
  ];
}

class ConversationCubit extends Cubit<ConversationState> {
  final String id;
  final MessageRepository repository;
  final ChatImageService? images;
  RecipeImage? _uploadedImage;
  StreamSubscription<Conversation>? _subscription;
  Timer? _initialTimeout;
  int _revision = 0;
  String? _pendingRequestId;
  ConversationCubit({required this.id, required this.repository, this.images})
    : super(const ConversationState());

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
            error: 'Chưa mở được cuộc trò chuyện. Vui lòng thử lại.',
          ),
        );
      }
    }

    _initialTimeout = Timer(const Duration(seconds: 20), fail);
    try {
      _subscription = repository.watchConversation(id).listen((thread) {
        _initialTimeout?.cancel();
        if (!isClosed && revision == _revision) {
          emit(state.copyWith(conversation: thread, loading: false));
        }
      }, onError: (Object _) => fail());
    } catch (_) {
      fail();
    }
  }

  void changeDraft(String value) {
    if (!isClosed && !state.sending) {
      if (value != state.draft) _pendingRequestId = null;
      emit(state.copyWith(draft: value));
    }
  }

  Future<void> pickImage() async {
    if (isClosed ||
        images == null ||
        state.sending ||
        state.pickingImage ||
        state.pickingRecipe ||
        state.conversation == null) {
      return;
    }
    emit(state.copyWith(pickingImage: true));
    try {
      final image = await images!.pick();
      if (isClosed) return;
      if (image != null) {
        _pendingRequestId = null;
        _uploadedImage = null;
      }
      emit(
        state.copyWith(
          image: image,
          clearRecipe: image != null,
          pickingImage: false,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            pickingImage: false,
            error:
                'Không mở được ảnh. Chọn ảnh hợp lệ, dung lượng tối đa 8 MB.',
          ),
        );
      }
    }
  }

  void removeImage() {
    if (isClosed || state.sending || state.pickingImage || state.pickingRecipe) {
      return;
    }
    _pendingRequestId = null;
    _uploadedImage = null;
    emit(state.copyWith(clearImage: true));
  }

  Future<void> pickRecipe(Future<ChatRecipe?> Function() picker) async {
    if (isClosed ||
        state.sending ||
        state.pickingImage ||
        state.pickingRecipe ||
        state.conversation == null) {
      return;
    }
    emit(state.copyWith(pickingRecipe: true));
    try {
      final selected = await picker();
      if (isClosed) return;
      if (selected != null) {
        _pendingRequestId = null;
        _uploadedImage = null;
      }
      emit(
        state.copyWith(
          recipe: selected,
          clearImage: selected != null,
          pickingRecipe: false,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            pickingRecipe: false,
            error: 'Chưa chọn được công thức. Nội dung đang soạn vẫn được giữ.',
          ),
        );
      }
    }
  }

  void removeRecipe() {
    if (isClosed || state.sending || state.pickingRecipe) return;
    _pendingRequestId = null;
    emit(state.copyWith(clearRecipe: true));
  }

  Future<void> send() async {
    if (isClosed || !state.canSend) return;
    final text = state.draft.trim();
    _pendingRequestId ??= List.generate(
      16,
      (_) => Random.secure().nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    emit(
      state.copyWith(
        sending: true,
        uploadingImage: state.image != null && _uploadedImage == null,
      ),
    );
    try {
      final selected = state.image;
      if (selected != null && _uploadedImage == null) {
        _uploadedImage = await images!.upload(selected);
        if (isClosed) return;
        emit(state.copyWith(uploadingImage: false));
      }
      await repository.send(
        id,
        text,
        requestId: _pendingRequestId!,
        image: _uploadedImage,
        recipe: state.recipe,
      );
      // Snapshot là nguồn duy nhất của lịch sử, tránh chèn trùng tin vừa gửi.
      if (!isClosed) {
        _pendingRequestId = null;
        _uploadedImage = null;
        emit(
          state.copyWith(
            sending: false,
            uploadingImage: false,
            draft: '',
            clearImage: true,
            clearRecipe: true,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            sending: false,
            uploadingImage: false,
            error: 'Chưa gửi được tin nhắn. Nội dung vẫn được giữ để thử lại.',
          ),
        );
      }
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
