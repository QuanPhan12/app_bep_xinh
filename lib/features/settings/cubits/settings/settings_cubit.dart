import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/features/profile/models/profile_data.dart';
import 'package:app_bep_xinh/features/profile/services/profile_service.dart';

class SettingsState extends Equatable {
  final UserProfile? account;
  final bool loading;
  final bool saving;
  final String? message;
  final int noticeId;
  const SettingsState({
    this.account,
    this.loading = true,
    this.saving = false,
    this.message,
    this.noticeId = 0,
  });
  SettingsState copyWith({
    UserProfile? account,
    bool? loading,
    bool? saving,
    String? message,
    int? noticeId,
  }) => SettingsState(
    account: account ?? this.account,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    message: message,
    noticeId: noticeId ?? this.noticeId,
  );
  @override
  List<Object?> get props => [account, loading, saving, message, noticeId];
}

class SettingsCubit extends Cubit<SettingsState> {
  final ProfileService service;
  late final StreamSubscription<UserProfile> _subscription;
  UserProfile? _latestAccount;
  Future<void>? _loadTask;
  SettingsCubit({required this.service}) : super(const SettingsState()) {
    _subscription = service.changes.listen((account) {
      _latestAccount = account;
      if (!isClosed && state.account != null) {
        emit(state.copyWith(account: account));
      }
    });
  }

  Future<void> load() {
    if (isClosed) return Future.value();
    return _loadTask ??= _load().whenComplete(() => _loadTask = null);
  }

  Future<void> _load() async {
    emit(state.copyWith(loading: true));
    try {
      final account = await service.fetchAccount();
      if (!isClosed) {
        emit(
          state.copyWith(account: _latestAccount ?? account, loading: false),
        );
      }
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          state.copyWith(
            loading: false,
            message: 'Không tải được cài đặt. Vui lòng thử lại.',
          ),
        );
      }
    }
  }

  Future<void> setShowBio(bool value) async {
    if (isClosed ||
        state.saving ||
        state.account == null ||
        state.account!.showBio == value) {
      return;
    }
    emit(state.copyWith(saving: true));
    try {
      final account = await service.setShowBio(value);
      if (!isClosed) emit(state.copyWith(account: account, saving: false));
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          state.copyWith(
            saving: false,
            message: 'Chưa lưu được cài đặt. Vui lòng thử lại.',
            noticeId: state.noticeId + 1,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    final cancellation = _subscription.cancel();
    await super.close();
    await cancellation;
  }
}
