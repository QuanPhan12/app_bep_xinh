import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/profile_data.dart';
import '../../services/profile_service.dart';
import '../../../recipes/models/recipe_image.dart';

class ProfileEditState extends Equatable {
  final String name;
  final String bio;
  final bool showErrors;
  final bool saving;
  final bool saved;
  final String? message;
  final int noticeId;
  final bool loading;
  final bool loadFailed;
  final RecipeImage? avatar;
  final String? avatarUrl;
  final bool pickingAvatar;
  const ProfileEditState({
    required this.name,
    required this.bio,
    this.showErrors = false,
    this.saving = false,
    this.saved = false,
    this.message,
    this.noticeId = 0,
    this.loading = false,
    this.loadFailed = false,
    this.avatar,
    this.avatarUrl,
    this.pickingAvatar = false,
  });

  String? get nameError => name.trim().isEmpty
      ? 'Nhập tên hiển thị.'
      : name.trim().length > 60
      ? 'Tên tối đa 60 ký tự.'
      : null;
  String? get bioError =>
      bio.trim().length > 200 ? 'Giới thiệu tối đa 200 ký tự.' : null;
  ProfileEditState copyWith({
    String? name,
    String? bio,
    bool? showErrors,
    bool? saving,
    bool? saved,
    String? message,
    int? noticeId,
    bool? loading,
    bool? loadFailed,
    RecipeImage? avatar,
    String? avatarUrl,
    bool? pickingAvatar,
  }) => ProfileEditState(
    name: name ?? this.name,
    bio: bio ?? this.bio,
    showErrors: showErrors ?? this.showErrors,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    message: message,
    noticeId: noticeId ?? this.noticeId,
    loading: loading ?? this.loading,
    loadFailed: loadFailed ?? this.loadFailed,
    avatar: avatar ?? this.avatar,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    pickingAvatar: pickingAvatar ?? this.pickingAvatar,
  );
  @override
  List<Object?> get props => [
    name,
    bio,
    showErrors,
    saving,
    saved,
    message,
    noticeId,
    loading,
    loadFailed,
    avatar,
    avatarUrl,
    pickingAvatar,
  ];
}

class ProfileEditCubit extends Cubit<ProfileEditState> {
  final ProfileService service;
  Future<void>? _loadTask;
  String? _originalName;
  String? _originalBio;

  bool get hasUnsavedChanges =>
      !state.saved &&
      _originalName != null &&
      (state.avatar != null ||
          state.name.trim() != _originalName!.trim() ||
          state.bio.trim() != _originalBio!.trim());
  ProfileEditCubit({required this.service, UserProfile? account})
    : super(
        ProfileEditState(
          name: account?.name ?? '',
          bio: account?.bio ?? '',
          loading: account == null,
          avatarUrl: account?.avatarUrl,
        ),
      ) {
    _originalName = account?.name;
    _originalBio = account?.bio;
  }

  Future<void> load() {
    if (isClosed) return Future.value();
    return _loadTask ??= _load().whenComplete(() => _loadTask = null);
  }

  Future<void> _load() async {
    emit(state.copyWith(loading: true, loadFailed: false));
    try {
      final account = await service.fetchAccount();
      if (!isClosed) {
        _originalName = account.name;
        _originalBio = account.bio;
        emit(
          state.copyWith(
            name: account.name,
            bio: account.bio,
            avatarUrl: account.avatarUrl,
            loading: false,
          ),
        );
      }
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          state.copyWith(
            loading: false,
            loadFailed: true,
            message: 'Không tải được hồ sơ. Vui lòng thử lại.',
          ),
        );
      }
    }
  }

  void changeName(String value) {
    if (!isClosed && !state.saving && !state.loading && !state.loadFailed) {
      emit(state.copyWith(name: value));
    }
  }

  void changeBio(String value) {
    if (!isClosed && !state.saving && !state.loading && !state.loadFailed) {
      emit(state.copyWith(bio: value));
    }
  }

  bool get canChangeAvatar => service is ProfileAvatarService;

  Future<void> pickAvatar() async {
    if (isClosed ||
        state.saving ||
        state.pickingAvatar ||
        state.loading ||
        state.loadFailed ||
        !canChangeAvatar) {
      return;
    }
    emit(state.copyWith(pickingAvatar: true));
    try {
      final image = await (service as ProfileAvatarService).pickAvatar();
      if (!isClosed && image != null) emit(state.copyWith(avatar: image));
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            message: 'Không chọn được ảnh đại diện. Vui lòng thử lại.',
            noticeId: state.noticeId + 1,
          ),
        );
      }
    } finally {
      if (!isClosed) emit(state.copyWith(pickingAvatar: false));
    }
  }

  Future<void> save() async {
    if (isClosed ||
        state.saving ||
        state.pickingAvatar ||
        state.saved ||
        state.loading ||
        state.loadFailed) {
      return;
    }
    emit(state.copyWith(showErrors: true));
    if (state.nameError != null || state.bioError != null) return;
    emit(state.copyWith(saving: true));
    try {
      if (state.avatar case final image?) {
        await (service as ProfileAvatarService).updateProfileWithAvatar(
          name: state.name,
          bio: state.bio,
          image: image,
        );
      } else {
        await service.updateProfile(name: state.name, bio: state.bio);
      }
      if (!isClosed) emit(state.copyWith(saving: false, saved: true));
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          state.copyWith(
            saving: false,
            message: 'Chưa cập nhật được hồ sơ. Vui lòng thử lại.',
            noticeId: state.noticeId + 1,
          ),
        );
      }
    }
  }
}
