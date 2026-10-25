import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_author.dart';
import 'package:equatable/equatable.dart';

import 'profile_data.dart';

class PublicProfileUser extends Equatable {
  final RecipeAuthor identity;
  final String bio;
  const PublicProfileUser({required this.identity, this.bio = ''});
  factory PublicProfileUser.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return PublicProfileUser(
      identity: RecipeAuthor.fromJson(json),
      bio: reader.boolean('showBio', fallback: true)
          ? reader.string('bio', fallback: '', allowEmpty: true)
          : '',
    );
  }
  factory PublicProfileUser.fromAccount(UserProfile account) =>
      PublicProfileUser(
        identity: RecipeAuthor(
          id: account.id,
          name: account.name,
          handle: account.handle,
          avatarAsset: account.avatarAsset,
        ),
        bio: account.showBio ? account.bio : '',
      );
  @override
  List<Object?> get props => [identity, bio];
}

class PublicProfileData extends Equatable {
  final PublicProfileUser user;
  final List<RecipeItem> recipes;
  PublicProfileData({required this.user, required List<RecipeItem> recipes})
    : recipes = List.unmodifiable(recipes);
  PublicProfileData copyWith({
    PublicProfileUser? user,
    List<RecipeItem>? recipes,
  }) => PublicProfileData(
    user: user ?? this.user,
    recipes: recipes ?? this.recipes,
  );
  @override
  List<Object?> get props => [user, recipes];
}
