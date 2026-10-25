import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';

class UserProfile extends Equatable {
  final String id;
  final String name;
  final String handle;
  final String bio;
  final int cookedCount;
  final bool showBio;
  final String? avatarAsset;

  const UserProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.bio,
    required this.cookedCount,
    required this.showBio,
    this.avatarAsset,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return UserProfile(
      id: reader.string('id'),
      name: reader.string('name'),
      handle: reader.string('handle'),
      bio: reader.string('bio', allowEmpty: true),
      cookedCount: reader.integer('cookedCount'),
      showBio: reader.boolean('showBio', fallback: true),
      avatarAsset: reader.optionalString('avatarAsset'),
    );
  }

  UserProfile copyWith({String? name, String? bio, bool? showBio}) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        handle: handle,
        bio: bio ?? this.bio,
        cookedCount: cookedCount,
        showBio: showBio ?? this.showBio,
        avatarAsset: avatarAsset,
      );

  @override
  List<Object?> get props => [
    id,
    name,
    handle,
    bio,
    cookedCount,
    showBio,
    avatarAsset,
  ];
}

class ProfileData extends Equatable {
  final UserProfile account;
  final List<RecipeItem> recipes;
  final Set<String> ownRecipeIds;

  ProfileData({
    required this.account,
    required List<RecipeItem> recipes,
    required Set<String> ownRecipeIds,
  }) : recipes = List.unmodifiable(recipes),
       ownRecipeIds = Set.unmodifiable(ownRecipeIds);

  List<RecipeItem> get ownRecipes =>
      recipes.where((recipe) => ownRecipeIds.contains(recipe.id)).toList();
  List<RecipeItem> get savedRecipes =>
      recipes.where((recipe) => recipe.isFavorite).toList();

  ProfileData copyWith({UserProfile? account, List<RecipeItem>? recipes}) =>
      ProfileData(
        account: account ?? this.account,
        recipes: recipes ?? this.recipes,
        ownRecipeIds: ownRecipeIds,
      );

  @override
  List<Object?> get props => [account, recipes, ownRecipeIds];
}
