import 'dart:async';

import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/core/utils/async_serial_queue.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_author.dart';

import '../models/profile_data.dart';
import '../models/public_profile_data.dart';
import 'public_profile_service.dart';

abstract interface class ProfileService {
  Stream<UserProfile> get changes;
  Future<UserProfile> fetchAccount();
  Future<ProfileData> fetchProfile();
  Future<UserProfile> updateProfile({
    required String name,
    required String bio,
  });
  Future<UserProfile> setShowBio(bool value);
  Future<void> dispose();
}

/// Mock API trong phiên; widget và Cubit không chứa dữ liệu mẫu.
class MockProfileService implements ProfileService, PublicProfileService {
  final MockApiClient api;
  final RecipeFavoritesService favorites;
  final _writes = AsyncSerialQueue();
  final _changes = StreamController<UserProfile>.broadcast();
  UserProfile? _account;
  bool _disposed = false;

  MockProfileService(this.api, this.favorites);

  @override
  Stream<UserProfile> get changes => _changes.stream;
  @override
  Stream<PublicProfileUser> get publicChanges =>
      changes.map(PublicProfileUser.fromAccount);

  UserProfile _readAccount(Map<String, dynamic> json) {
    final account = json['account'];
    if (account is! Map<String, dynamic>) {
      throw const FormatException('Expected account object');
    }
    return UserProfile.fromJson(account);
  }

  @override
  Future<UserProfile> fetchAccount() async {
    final json = await api.get('profile');
    await _writes.settled;
    return _account ?? _readAccount(json);
  }

  @override
  Future<ProfileData> fetchProfile() async {
    final (profile, catalog) = await (
      api.get('profile'),
      api.get('recipe_details'),
    ).wait;
    final ids = JsonReader(profile).strings('recipeIds');
    requireUniqueIds(ids, 'profile recipes');
    final recipes = await Future.wait(
      JsonReader(catalog).objects('recipes').map((json) async {
        final reader = JsonReader(json);
        final id = reader.string('id');
        return RecipeItem.fromRecipeJson(
          json,
          isFavorite: await favorites.isFavorite(
            id,
            fallback: reader.boolean('isFavorite'),
          ),
        );
      }),
    );
    requireUniqueIds(recipes.map((recipe) => recipe.id), 'recipe catalog');
    if (!ids.every((id) => recipes.any((recipe) => recipe.id == id))) {
      throw const FormatException('Unknown profile recipe');
    }
    await _writes.settled;
    return ProfileData(
      account: _account ?? _readAccount(profile),
      recipes: recipes,
      ownRecipeIds: ids.toSet(),
    );
  }

  @override
  Future<PublicProfileData> fetchPublicProfile(String userId) async {
    final (profiles, catalog) = await (
      api.get('public_profiles'),
      api.get('recipe_details'),
    ).wait;
    final users = JsonReader(profiles)
        .objects('users')
        .map(PublicProfileUser.fromJson)
        .toList();
    requireUniqueIds(users.map((user) => user.identity.id!), 'public user ids');
    final matching = users
        .where((user) => user.identity.id == userId)
        .firstOrNull;
    if (matching == null) throw const PublicProfileNotFoundException();
    final entries = JsonReader(catalog).objects('recipes');
    requireUniqueIds(
      entries.map((entry) => JsonReader(entry).string('id')),
      'recipe catalog',
    );
    final authored = entries.where(
      (entry) => RecipeAuthor.read(entry['author']).id == userId,
    );
    final recipes = await Future.wait(
      authored.map((json) async {
        final reader = JsonReader(json);
        return RecipeItem.fromRecipeJson(
          json,
          isFavorite: await favorites.isFavorite(
            reader.string('id'),
            fallback: reader.boolean('isFavorite'),
          ),
        );
      }),
    );
    await _writes.settled;
    return PublicProfileData(
      user: _account?.id == userId
          ? PublicProfileUser.fromAccount(_account!)
          : matching,
      recipes: recipes,
    );
  }

  Future<UserProfile> _update(UserProfile Function(UserProfile) change) =>
      _writes.run(() async {
        if (_disposed) throw StateError('Profile service disposed');
        final current = _account ?? _readAccount(await api.get('profile'));
        final next = change(current);
        await api.simulateWrite();
        if (_disposed) throw StateError('Profile service disposed');
        _account = next;
        _changes.add(next);
        return next;
      });

  @override
  Future<UserProfile> updateProfile({
    required String name,
    required String bio,
  }) {
    final normalizedName = name.trim();
    final normalizedBio = bio.trim();
    if (normalizedName.isEmpty ||
        normalizedName.length > 60 ||
        normalizedBio.length > 200) {
      throw const FormatException('Invalid profile');
    }
    return _update(
      (account) => account.copyWith(name: normalizedName, bio: normalizedBio),
    );
  }

  @override
  Future<UserProfile> setShowBio(bool value) =>
      _update((account) => account.copyWith(showBio: value));

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _changes.close();
  }
}
