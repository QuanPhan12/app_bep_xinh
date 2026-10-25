import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/features/profile/cubits/profile/profile_cubit.dart';
import 'package:app_bep_xinh/features/profile/cubits/profile_edit/profile_edit_cubit.dart';
import 'package:app_bep_xinh/features/profile/models/profile_data.dart';
import 'package:app_bep_xinh/features/settings/cubits/settings/settings_cubit.dart';

import '../../support/profile_fakes.dart';
import '../../support/recipe_detail_fakes.dart';

void main() {
  late StubProfileService service;
  late StubRecipeFavoritesService favorites;
  late ProfileCubit cubit;
  setUp(() {
    service = StubProfileService();
    favorites = StubRecipeFavoritesService();
    cubit = ProfileCubit(service: service, favorites: favorites);
  });
  tearDown(() async {
    await cubit.close();
    await service.dispose();
    await favorites.dispose();
  });

  test(
    'load deduplicates, retries and keeps loaded content on refresh failure',
    () async {
      final pending = Completer<ProfileData>();
      service.onFetch = () => pending.future;
      final loading = cubit.load();
      expect(identical(loading, cubit.load()), isTrue);
      pending.completeError(StateError('offline'));
      await loading;
      expect(cubit.state.status, ProfileStatus.failure);
      expect(cubit.state.data, isNull);
      service.onFetch = null;
      await cubit.load();
      expect(cubit.state.visibleRecipes.length, 2);
      service.onFetch = () => Future.error(StateError('offline'));
      await cubit.load();
      expect(cubit.state.data, isNotNull);
      expect(cubit.state.noticeId, 1);
    },
  );

  test(
    'account and favorites received during load override stale snapshot',
    () async {
      final pending = Completer<ProfileData>();
      service.onFetch = () => pending.future;
      final loading = cubit.load();
      service.publish(
        service.account.copyWith(name: 'Tên mới', showBio: false),
      );
      await favorites.setFavorite('bo_ne_tieu_den', true);
      pending.complete(profileFixture());
      await loading;
      expect(cubit.state.data!.account.name, 'Tên mới');
      expect(cubit.state.data!.account.showBio, isFalse);
      cubit.selectTab(ProfileTab.saved);
      expect(
        cubit.state.visibleRecipes.map((r) => r.id),
        contains('bo_ne_tieu_den'),
      );
    },
  );

  test('favorite failure retains saved recipe, retries, deduplicates and reflects external changes', () async {
    await cubit.load();
    cubit.selectTab(ProfileTab.saved);
    final saved = cubit.state.visibleRecipes.single.id;
    final pending = Completer<void>();
    favorites.onSet = (_, _) => pending.future;
    final writing = cubit.toggleFavorite(saved);
    await cubit.toggleFavorite(saved);
    expect(favorites.writes, 1);
    pending.completeError(StateError('offline'));
    await writing;
    expect(cubit.state.visibleRecipes, hasLength(1));
    expect(cubit.state.noticeId, 1);
    expect(cubit.state.savingFavorites, isEmpty);
    favorites.onSet = null;
    await cubit.toggleFavorite(saved);
    expect(cubit.state.visibleRecipes, isEmpty);
    await favorites.setFavorite('ca_hoi_ap_chao', true);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.visibleRecipes.single.id, 'ca_hoi_ap_chao');
  });

  test('load after disposal does not emit or read again', () async {
    final pending = Completer<ProfileData>();
    service.onFetch = () => pending.future;
    final loading = cubit.load();
    await cubit.close();
    pending.complete(profileFixture());
    await loading;
    await cubit.load();
    expect(service.reads, 1);
  });

  test('edit validates clear and retype, retries failures and prevents duplicate saves', () async {
    final edit = ProfileEditCubit(service: service, account: service.account);
    addTearDown(edit.close);
    edit.changeName('');
    await edit.save();
    expect(service.writes, 0);
    expect(edit.state.nameError, isNotNull);
    edit.changeName('Tên mới');
    expect(edit.state.nameError, isNull);
    final pending = Completer<void>();
    service.onWrite = () => pending.future;
    final saving = edit.save();
    await edit.save();
    edit.changeName('Không ghi đè khi lưu');
    expect(service.writes, 1);
    pending.completeError(StateError('offline'));
    await saving;
    expect(edit.state.saved, isFalse);
    expect(edit.state.noticeId, 1);
    service.onWrite = null;
    await edit.save();
    expect(edit.state.saved, isTrue);
    expect(service.account.name, 'Tên mới');
  });

  test('settings fails without changing confirmed value and synchronizes profile on retry', () async {
    await cubit.load();
    final settings = SettingsCubit(service: service);
    addTearDown(settings.close);
    await settings.load();
    final pending = Completer<void>();
    service.onWrite = () => pending.future;
    final saving = settings.setShowBio(false);
    await settings.setShowBio(false);
    expect(service.writes, 1);
    pending.completeError(StateError('offline'));
    await saving;
    expect(settings.state.account!.showBio, isTrue);
    expect(settings.state.noticeId, 1);
    service.onWrite = null;
    await settings.setShowBio(false);
    await Future<void>.delayed(Duration.zero);
    expect(settings.state.account!.showBio, isFalse);
    expect(cubit.state.data!.account.showBio, isFalse);
  });
}
