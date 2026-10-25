import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';

import '../../models/profile_data.dart';

enum ProfileStatus { initial, loading, ready, failure }

enum ProfileTab { recipes, saved }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileData? data;
  final ProfileTab tab;
  final Set<String> savingFavorites;
  final String? message;
  final int noticeId;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.data,
    this.tab = ProfileTab.recipes,
    this.savingFavorites = const {},
    this.message,
    this.noticeId = 0,
  });

  List<RecipeItem> get visibleRecipes =>
      (tab == ProfileTab.recipes ? data?.ownRecipes : data?.savedRecipes) ??
      const [];

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileData? data,
    ProfileTab? tab,
    Set<String>? savingFavorites,
    String? message,
    int? noticeId,
  }) => ProfileState(
    status: status ?? this.status,
    data: data ?? this.data,
    tab: tab ?? this.tab,
    savingFavorites: savingFavorites == null
        ? this.savingFavorites
        : Set.unmodifiable(savingFavorites),
    message: message,
    noticeId: noticeId ?? this.noticeId,
  );

  @override
  List<Object?> get props => [
    status,
    data,
    tab,
    savingFavorites,
    message,
    noticeId,
  ];
}
