import 'package:equatable/equatable.dart';

import 'package:app_bep_xinh/features/home/models/recipe_item.dart';

import 'user_profile.dart';

export 'user_profile.dart';

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
