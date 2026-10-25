import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../../models/profile_data.dart';
import '../../services/profile_service.dart';
import 'profile_state.dart';

export 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileService service;
  final RecipeFavoritesService favorites;
  late final StreamSubscription<UserProfile> _accountSubscription;
  late final StreamSubscription<RecipeFavoriteChange> _favoriteSubscription;
  final _favoriteOverrides = <String, bool>{};
  UserProfile? _latestAccount;
  Future<void>? _loadTask;

  ProfileCubit({required this.service, required this.favorites})
    : super(const ProfileState()) {
    _accountSubscription = service.changes.listen((account) {
      _latestAccount = account;
      if (!isClosed && state.data != null) {
        emit(state.copyWith(data: state.data!.copyWith(account: account)));
      }
    });
    _favoriteSubscription = favorites.changes.listen((change) {
      _favoriteOverrides[change.recipeId] = change.isFavorite;
      if (!isClosed && state.data != null) {
        emit(state.copyWith(data: _applyFavorites(state.data!)));
      }
    });
  }

  ProfileData _applyFavorites(ProfileData data) => data.copyWith(
    account: _latestAccount ?? data.account,
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
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final data = await service.fetchProfile();
      if (!isClosed) {
        emit(
          state.copyWith(
            status: ProfileStatus.ready,
            data: _applyFavorites(data),
          ),
        );
      }
    } catch (error, stack) {
      if (isClosed) return;
      addError(error, stack);
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          message: 'Không tải được hồ sơ. Vui lòng thử lại.',
          noticeId: state.data == null ? state.noticeId : state.noticeId + 1,
        ),
      );
    }
  }

  void selectTab(ProfileTab tab) {
    if (!isClosed) emit(state.copyWith(tab: tab));
  }

  Future<void> toggleFavorite(String id) async {
    if (isClosed || state.savingFavorites.contains(id)) return;
    final matches = state.data?.recipes.where((recipe) => recipe.id == id);
    if (matches == null || matches.isEmpty) return;
    final value = !matches.first.isFavorite;
    emit(state.copyWith(savingFavorites: {...state.savingFavorites, id}));
    try {
      await favorites.setFavorite(id, value);
      _favoriteOverrides[id] = value;
      if (!isClosed && state.data != null) {
        emit(state.copyWith(data: _applyFavorites(state.data!)));
      }
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
            savingFavorites: {...state.savingFavorites}..remove(id),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    final tasks = [
      _accountSubscription.cancel(),
      _favoriteSubscription.cancel(),
    ];
    await super.close();
    await Future.wait(tasks);
  }
}
