import 'package:equatable/equatable.dart';

import '../../models/public_profile_data.dart';

enum PublicProfileStatus { initial, loading, ready, failure, notFound }

class PublicProfileState extends Equatable {
  final PublicProfileStatus status;
  final PublicProfileData? data;
  final Set<String> savingFavorites;
  final String? message;
  final int noticeId;
  const PublicProfileState({
    this.status = PublicProfileStatus.initial,
    this.data,
    this.savingFavorites = const {},
    this.message,
    this.noticeId = 0,
  });

  PublicProfileState copyWith({
    PublicProfileStatus? status,
    PublicProfileData? data,
    bool clearData = false,
    Set<String>? savingFavorites,
    String? message,
    int? noticeId,
  }) => PublicProfileState(
    status: status ?? this.status,
    data: clearData ? null : data ?? this.data,
    savingFavorites: savingFavorites == null
        ? this.savingFavorites
        : Set.unmodifiable(savingFavorites),
    message: message,
    noticeId: noticeId ?? this.noticeId,
  );
  @override
  List<Object?> get props => [status, data, savingFavorites, message, noticeId];
}
