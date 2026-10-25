import 'dart:async';

import 'package:app_bep_xinh/features/profile/cubits/public_profile/public_profile_cubit.dart';
import 'package:app_bep_xinh/features/profile/models/public_profile_data.dart';
import 'package:app_bep_xinh/features/profile/services/public_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/public_profile_fakes.dart';
import '../../support/recipe_detail_fakes.dart';

void main() {
  late StubPublicProfileService service;
  late StubRecipeFavoritesService favorites;
  late PublicProfileCubit cubit;
  setUp(() {
    service = StubPublicProfileService();
    favorites = StubRecipeFavoritesService();
    cubit = PublicProfileCubit(
      userId: 'linh_nguyen',
      service: service,
      favorites: favorites,
    );
  });
  tearDown(() async {
    await cubit.close();
    await service.dispose();
    await favorites.dispose();
  });

  test('load deduplicates, retries, distinguishes not found and never substitutes another user', () async {
    final pending = Completer<PublicProfileData>();
    service.onFetch = (_) => pending.future;
    final loading = cubit.load();
    expect(identical(loading, cubit.load()), isTrue);
    expect(service.requests, ['linh_nguyen']);
    pending.completeError(StateError('offline'));
    await loading;
    expect(cubit.state.status, PublicProfileStatus.failure);
    service.onFetch = (_) async => publicProfileFixture('mai_anh');
    await cubit.load();
    expect(cubit.state.data, isNull);
    expect(cubit.state.status, PublicProfileStatus.failure);
    service.onFetch = null;
    await cubit.load();
    expect(cubit.state.data!.user.identity.id, 'linh_nguyen');
    service.onFetch = (_) =>
        Future.error(const PublicProfileNotFoundException());
    await cubit.load();
    expect(cubit.state.status, PublicProfileStatus.notFound);
    expect(cubit.state.data, isNull);
  });

  test(
    'late favorite and matching public user changes override a stale response',
    () async {
      final pending = Completer<PublicProfileData>();
      service.onFetch = (_) => pending.future;
      final loading = cubit.load();
      await favorites.setFavorite('tofu_tomato', true);
      service.controller.add(publicProfileFixture('mai_anh').user);
      final current = publicProfileFixture().user;
      final updated = PublicProfileUser(
        identity: current.identity,
        bio: 'Giới thiệu mới',
      );
      service.controller.add(updated);
      await Future<void>.value();
      pending.complete(publicProfileFixture());
      await loading;
      expect(cubit.state.data!.user, updated);
      expect(
        cubit.state.data!.recipes
            .firstWhere((recipe) => recipe.id == 'tofu_tomato')
            .isFavorite,
        isTrue,
      );
      service.controller.add(publicProfileFixture('bep_xinh').user);
      await Future<void>.value();
      expect(cubit.state.data!.user, updated);
    },
  );

  test('favorite writes deduplicate, ignore unknown recipes, preserve state on failure and retry', () async {
    await cubit.load();
    await cubit.toggleFavorite('bo_ne_tieu_den');
    expect(favorites.writes, 0);
    final pending = Completer<void>();
    favorites.onSet = (_, _) => pending.future;
    final writing = cubit.toggleFavorite('tofu_tomato');
    await cubit.toggleFavorite('tofu_tomato');
    expect(favorites.writes, 1);
    pending.completeError(StateError('offline'));
    await writing;
    expect(cubit.state.savingFavorites, isEmpty);
    expect(
      cubit.state.data!.recipes
          .firstWhere((recipe) => recipe.id == 'tofu_tomato')
          .isFavorite,
      isFalse,
    );
    expect(cubit.state.noticeId, 1);
    favorites.onSet = null;
    await cubit.toggleFavorite('tofu_tomato');
    expect(
      cubit.state.data!.recipes
          .firstWhere((recipe) => recipe.id == 'tofu_tomato')
          .isFavorite,
      isTrue,
    );
  });

  test(
    'refresh failure retains visible content; closing ignores in-flight data',
    () async {
      await cubit.load();
      service.onFetch = (_) => Future.error(StateError('offline'));
      await cubit.load();
      expect(cubit.state.data!.user.identity.id, 'linh_nguyen');
      expect(cubit.state.noticeId, 1);
      final pending = Completer<PublicProfileData>();
      service.onFetch = (_) => pending.future;
      final loading = cubit.load();
      await cubit.close();
      pending.complete(publicProfileFixture());
      await expectLater(loading, completes);
    },
  );
}
