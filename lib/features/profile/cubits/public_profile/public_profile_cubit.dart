import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../../models/public_profile_data.dart';
import '../../services/public_profile_service.dart';
import 'public_profile_state.dart';

export 'public_profile_state.dart';

class PublicProfileCubit extends Cubit<PublicProfileState> {
  final String userId;
  final PublicProfileService service;
  final RecipeFavoritesService favorites;
  final _favoriteOverrides = <String, bool>{};
  late final StreamSubscription<RecipeFavoriteChange> _favoritesSubscription;
  late final StreamSubscription<PublicProfileUser> _userSubscription;
  PublicProfileUser? _latestUser;
  Future<void>? _loadTask;

  PublicProfileCubit({
    required this.userId,
    required this.service,
    required this.favorites,
  }) : super(const PublicProfileState()) {
    _favoritesSubscription = favorites.changes.listen(
      (change) {
        if (isClosed) return;
        _favoriteOverrides[change.recipeId] = change.isFavorite;
        if (state.data != null) emit(state.copyWith(data: _apply(state.data!)));
      },
      onError: (Object error, StackTrace stack) {
        if (!isClosed) addError(error, stack);
      },
    );
    _userSubscription = service.publicChanges.listen(
      (user) {
        if (isClosed || user.identity.id != userId) return;
        _latestUser = user;
        if (state.data != null) emit(state.copyWith(data: _apply(state.data!)));
      },
      onError: (Object error, StackTrace stack) {
        if (!isClosed) addError(error, stack);
      },
    );
  }

  PublicProfileData _apply(PublicProfileData data) => data.copyWith(
    user: _latestUser ?? data.user,
    recipes: data.recipes
        .map(
          (recipe) => recipe.copyWith(
            isFavorite: _favoriteOverrides[recipe.id] ?? recipe.isFavorite,
          ),
        )
        .toList(),
  );

  Future<void> load() {
    if (isClosed) return Future.value();
    return _loadTask ??= _load().whenComplete(() => _loadTask = null);
  }

  Future<void> _load() async {
    emit(state.copyWith(status: PublicProfileStatus.loading));
    try {
      final data = await service.fetchPublicProfile(userId);
      if (isClosed) return;
      if (data.user.identity.id != userId) {
        throw const FormatException('Mismatched public profile');
      }
      emit(
        state.copyWith(status: PublicProfileStatus.ready, data: _apply(data)),
      );
    } catch (error, stack) {
      if (isClosed) return;
      addError(error, stack);
      final notFound = error is PublicProfileNotFoundException;
      emit(
        state.copyWith(
          status: notFound
              ? PublicProfileStatus.notFound
              : PublicProfileStatus.failure,
          clearData: notFound,
          message: notFound
              ? 'Không tìm thấy hồ sơ này.'
              : 'Không tải được hồ sơ. Vui lòng thử lại.',
          noticeId: state.data == null || notFound
              ? state.noticeId
              : state.noticeId + 1,
        ),
      );
    }
  }

  Future<void> toggleFavorite(String recipeId) async {
    if (isClosed || state.savingFavorites.contains(recipeId)) return;
    final recipe = state.data?.recipes
        .where((item) => item.id == recipeId)
        .firstOrNull;
    if (recipe == null) return;
    final value = !recipe.isFavorite;
    emit(state.copyWith(savingFavorites: {...state.savingFavorites, recipeId}));
    try {
      await favorites.setFavorite(recipeId, value);
      if (isClosed) return;
      _favoriteOverrides[recipeId] = value;
      if (state.data != null) emit(state.copyWith(data: _apply(state.data!)));
    } catch (error, stack) {
      if (!isClosed) {
        addError(error, stack);
        emit(
          state.copyWith(
            message: 'Chưa lưu được món yêu thích. Vui lòng thử lại.',
            noticeId: state.noticeId + 1,
          ),
        );
      }
    } finally {
      if (!isClosed) {
        emit(
          state.copyWith(
            savingFavorites: {...state.savingFavorites}..remove(recipeId),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    final tasks = [_favoritesSubscription.cancel(), _userSubscription.cancel()];
    await super.close();
    await Future.wait(tasks);
  }
}
