import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../../models/profile_data.dart';
import '../../services/profile_service.dart';
import 'profile_state.dart';

export 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  static const _loadTimeout = Duration(seconds: 20);
  final ProfileService service;
  final RecipeFavoritesService favorites;
  final Future<int> Function()? loadCookingLogCount;
  int _countRevision = 0;
  late final StreamSubscription<UserProfile> _accountSubscription;
  late final StreamSubscription<RecipeFavoriteChange> _favoriteSubscription;
  final _favoriteOverrides = <String, bool>{};
  UserProfile? _latestAccount;
  Future<void>? _loadTask;

  ProfileCubit({
    required this.service,
    required this.favorites,
    this.loadCookingLogCount,
  }) : super(const ProfileState()) {
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
    if (loadCookingLogCount != null) unawaited(_loadCount(++_countRevision));
    try {
      // Firestore có thể chờ kết nối rất lâu. Kết thúc lần chờ của UI để
      // người dùng thử lại; Future gốc không bị hủy nhưng kết quả muộn
      // không được dùng để ghi đè dữ liệu của lần tải tiếp theo.
      final data = await service.fetchProfile().timeout(_loadTimeout);
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
          message: error is TimeoutException
              ? 'Tải hồ sơ quá lâu. Kiểm tra kết nối mạng và thử lại.'
              : 'Không tải được hồ sơ. Vui lòng thử lại.',
          noticeId: state.data == null ? state.noticeId : state.noticeId + 1,
        ),
      );
    }
  }

  Future<void> _loadCount(int revision) async {
    try {
      final count = await loadCookingLogCount!().timeout(_loadTimeout);
      if (!isClosed && revision == _countRevision) {
        emit(state.copyWith(cookingLogCount: count));
      }
    } catch (_) {
      if (!isClosed && revision == _countRevision) {
        emit(state.copyWith(clearCookingLogCount: true));
      }
    }
  }

  void selectTab(ProfileTab tab) {
    if (!isClosed) emit(state.copyWith(tab: tab));
  }

  void selectFilter(ProfileRecipeFilter filter) {
    if (!isClosed) emit(state.copyWith(filter: filter));
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
