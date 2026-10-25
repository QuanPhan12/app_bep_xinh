import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/profile_data.dart';
import '../../services/profile_service.dart';

class ProfileEditState extends Equatable {
  final String name;
  final String bio;
  final bool showErrors;
  final bool saving;
  final bool saved;
  final String? message;
  final int noticeId;
  const ProfileEditState({
    required this.name,
    required this.bio,
    this.showErrors = false,
    this.saving = false,
    this.saved = false,
    this.message,
    this.noticeId = 0,
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
  }) => ProfileEditState(
    name: name ?? this.name,
    bio: bio ?? this.bio,
    showErrors: showErrors ?? this.showErrors,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    message: message,
    noticeId: noticeId ?? this.noticeId,
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
  ];
}

class ProfileEditCubit extends Cubit<ProfileEditState> {
  final ProfileService service;
  ProfileEditCubit({required this.service, required UserProfile account})
    : super(ProfileEditState(name: account.name, bio: account.bio));

  void changeName(String value) {
    if (!isClosed && !state.saving) emit(state.copyWith(name: value));
  }

  void changeBio(String value) {
    if (!isClosed && !state.saving) emit(state.copyWith(bio: value));
  }

  Future<void> save() async {
    if (isClosed || state.saving || state.saved) return;
    emit(state.copyWith(showErrors: true));
    if (state.nameError != null || state.bioError != null) return;
    emit(state.copyWith(saving: true));
    try {
      await service.updateProfile(name: state.name, bio: state.bio);
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
