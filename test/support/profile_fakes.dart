import 'dart:async';

import 'package:app_bep_xinh/features/profile/models/profile_data.dart';
import 'package:app_bep_xinh/features/profile/services/profile_service.dart';

import 'mock_services.dart';

UserProfile accountFixture() => UserProfile.fromJson(
  fixtureJson('profile')['account'] as Map<String, dynamic>,
);
ProfileData profileFixture() => ProfileData(
  account: accountFixture(),
  recipes: homeFixture().recipes,
  ownRecipeIds: {'bo_ne_tieu_den', 'ca_hoi_ap_chao'},
);

class StubProfileService implements ProfileService {
  final controller = StreamController<UserProfile>.broadcast();
  UserProfile account = accountFixture();
  Future<ProfileData> Function()? onFetch;
  Future<UserProfile> Function()? onFetchAccount;
  Future<void> Function()? onWrite;
  int reads = 0;
  int writes = 0;
  @override
  Stream<UserProfile> get changes => controller.stream;
  @override
  Future<UserProfile> fetchAccount() =>
      onFetchAccount?.call() ?? Future.value(account);
  @override
  Future<ProfileData> fetchProfile() {
    reads++;
    return onFetch?.call() ??
        Future.value(profileFixture().copyWith(account: account));
  }

  void publish(UserProfile value) {
    account = value;
    controller.add(value);
  }

  @override
  Future<UserProfile> updateProfile({
    required String name,
    required String bio,
  }) async {
    writes++;
    await onWrite?.call();
    publish(account.copyWith(name: name.trim(), bio: bio.trim()));
    return account;
  }

  @override
  Future<UserProfile> setShowBio(bool value) async {
    writes++;
    await onWrite?.call();
    publish(account.copyWith(showBio: value));
    return account;
  }

  @override
  Future<void> dispose() => controller.close();
}
