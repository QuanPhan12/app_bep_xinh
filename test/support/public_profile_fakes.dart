import 'dart:async';

import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:app_bep_xinh/features/profile/models/public_profile_data.dart';
import 'package:app_bep_xinh/features/profile/services/public_profile_service.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_author.dart';

import 'mock_services.dart';

PublicProfileData publicProfileFixture([String userId = 'linh_nguyen']) {
  final users = JsonReader(fixtureJson('public_profiles')).objects('users');
  final json = users.where((item) => item['id'] == userId).firstOrNull;
  if (json == null) throw const PublicProfileNotFoundException();
  final entries = JsonReader(fixtureJson('recipe_details')).objects('recipes');
  return PublicProfileData(
    user: PublicProfileUser.fromJson(json),
    recipes: entries
        .where((item) => RecipeAuthor.read(item['author']).id == userId)
        .map((item) => RecipeItem.fromRecipeJson(item, isFavorite: false))
        .toList(),
  );
}

class StubPublicProfileService implements PublicProfileService {
  final controller = StreamController<PublicProfileUser>.broadcast();
  final requests = <String>[];
  Future<PublicProfileData> Function(String)? onFetch;
  @override
  Stream<PublicProfileUser> get publicChanges => controller.stream;
  @override
  Future<PublicProfileData> fetchPublicProfile(String id) {
    requests.add(id);
    return onFetch?.call(id) ?? Future.value(publicProfileFixture(id));
  }

  Future<void> dispose() => controller.close();
}
