import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';

import '../../models/profile_data.dart';

enum ProfileStatus { initial, loading, ready, failure }

enum ProfileTab { recipes, saved }

enum ProfileRecipeFilter { all, under30, from30 }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final ProfileData? data;
  final ProfileTab tab;
  final ProfileRecipeFilter filter;
  final Set<String> savingFavorites;
  final String? message;
  final int noticeId;
  final int? cookingLogCount;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.data,
    this.tab = ProfileTab.recipes,
    this.filter = ProfileRecipeFilter.all,
    this.savingFavorites = const {},
    this.message,
    this.noticeId = 0,
    this.cookingLogCount,
  });

  List<RecipeItem> get visibleRecipes =>
      ((tab == ProfileTab.recipes ? data?.ownRecipes : data?.savedRecipes) ??
              const <RecipeItem>[])
          .where(
            (recipe) => switch (filter) {
              ProfileRecipeFilter.all => true,
              ProfileRecipeFilter.under30 => recipe.cookTimeMinutes < 30,
              ProfileRecipeFilter.from30 => recipe.cookTimeMinutes >= 30,
            },
          )
          .toList();

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileData? data,
    ProfileTab? tab,
    ProfileRecipeFilter? filter,
    Set<String>? savingFavorites,
    String? message,
    int? noticeId,
    int? cookingLogCount,
    bool clearCookingLogCount = false,
  }) => ProfileState(
    status: status ?? this.status,
    data: data ?? this.data,
    tab: tab ?? this.tab,
    filter: filter ?? this.filter,
    savingFavorites: savingFavorites == null
        ? this.savingFavorites
        : Set.unmodifiable(savingFavorites),
    message: message,
    noticeId: noticeId ?? this.noticeId,
    cookingLogCount: clearCookingLogCount
        ? null
        : cookingLogCount ?? this.cookingLogCount,
  );

  @override
  List<Object?> get props => [
    status,
    data,
    tab,
    filter,
    savingFavorites,
    message,
    noticeId,
    cookingLogCount,
  ];
}
