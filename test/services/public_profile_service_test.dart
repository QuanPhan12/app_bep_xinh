import 'package:app_bep_xinh/core/services/json_reader.dart';
import 'package:app_bep_xinh/features/profile/services/profile_service.dart';
import 'package:app_bep_xinh/features/profile/services/public_profile_service.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_author.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mock_services.dart';

void main() {
  late MockRecipeFavoritesService favorites;
  late MockProfileService profiles;
  setUp(() {
    favorites = MockRecipeFavoritesService(fixtureApi());
    profiles = MockProfileService(fixtureApi(), favorites);
  });
  tearDown(() async {
    await profiles.dispose();
    await favorites.dispose();
  });

  test('every recipe author resolves by id and public recipes belong to that author only', () async {
    final recipes = JsonReader(fixtureJson('recipe_details'))
        .objects('recipes');
    for (final json in recipes) {
      final author = RecipeAuthor.read(json['author']);
      final profile = await profiles.fetchPublicProfile(author.id!);
      expect(profile.user.identity.id, author.id);
      expect(profile.recipes.map((recipe) => recipe.id), contains(json['id']));
      for (final recipe in profile.recipes) {
        final source = recipes.firstWhere((item) => item['id'] == recipe.id);
        expect(RecipeAuthor.read(source['author']).id, author.id);
        expect(
          recipe.image,
          (source['cover'] as Map<String, dynamic>?)?['assetPath'] ??
              source['image'] ??
              '',
        );
        expect(recipe.difficulty, isNot(anyOf('easy', 'medium', 'hard')));
      }
    }
    await expectLater(
      profiles.fetchPublicProfile('missing'),
      throwsA(isA<PublicProfileNotFoundException>()),
    );
    await expectLater(
      profiles.fetchPublicProfile('Mai Anh'),
      throwsA(isA<PublicProfileNotFoundException>()),
    );
  });

  test('public favorites use the viewer source without exposing another saved list', () async {
    await favorites.setFavorite('tofu_tomato', true);
    final linh = await profiles.fetchPublicProfile('linh_nguyen');
    expect(
      linh.recipes
          .firstWhere((recipe) => recipe.id == 'tofu_tomato')
          .isFavorite,
      isTrue,
    );
    expect(
      linh.recipes.map((recipe) => recipe.id),
      isNot(contains('bo_ne_tieu_den')),
    );
    final own = await profiles.fetchProfile();
    expect(
      own.savedRecipes.map((recipe) => recipe.id),
      contains('tofu_tomato'),
    );
    expect(own.ownRecipes.first.image, 'assets/images/bo_ne.jpg');
  });

  test('public projection honors hidden bio and applies account edits only to the matching id', () async {
    final before = await profiles.fetchAccount();
    final other = await profiles.fetchPublicProfile('linh_nguyen');
    final changed = profiles.publicChanges.first;
    await profiles.setShowBio(false);
    expect((await changed).bio, '');
    await profiles.updateProfile(name: 'Tên mới', bio: 'Giới thiệu riêng');
    final own = await profiles.fetchPublicProfile('mai_anh');
    expect(own.user.identity.name, 'Tên mới');
    expect(own.user.bio, '');
    expect((await profiles.fetchAccount()).bio, 'Giới thiệu riêng');
    expect((await profiles.fetchPublicProfile('linh_nguyen')).user, other.user);
    expect(before.id, 'mai_anh');
  });

  test(
    'legacy display names have no guessed id and malformed author objects fail',
    () {
      expect(RecipeAuthor.read('Bếp Xinh').id, isNull);
      expect(
        () => RecipeAuthor.read({'name': 'Bếp Xinh'}),
        throwsFormatException,
      );
      expect(
        () => RecipeAuthor.read({'id': 42, 'name': 'Bếp Xinh'}),
        throwsFormatException,
      );
      expect(() => RecipeAuthor.read(''), throwsFormatException);
    },
  );
}
