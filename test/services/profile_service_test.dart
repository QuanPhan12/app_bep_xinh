import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/features/profile/services/profile_service.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../support/mock_services.dart';

void main() {
  test(
    'profile uses catalog, exposes own recipes and shares favorite source',
    () async {
      final favorites = MockRecipeFavoritesService(fixtureApi());
      final service = MockProfileService(fixtureApi(), favorites);
      addTearDown(favorites.dispose);
      addTearDown(service.dispose);
      final data = await service.fetchProfile();
      expect(data.ownRecipes, hasLength(3));
      expect(data.recipes, hasLength(8));
      expect(data.savedRecipes.single.id, 'salad_uc_ga_me_rang');
      await favorites.setFavorite('tofu_tomato', true);
      final updated = await service.fetchProfile();
      expect(updated.savedRecipes.map((r) => r.id), contains('tofu_tomato'));
      expect(() => updated.recipes.clear(), throwsUnsupportedError);
    },
  );

  test('serialized edits and preferences preserve each other and survive another read', () async {
    final favorites = MockRecipeFavoritesService(fixtureApi());
    final service = MockProfileService(fixtureApi(), favorites);
    addTearDown(favorites.dispose);
    addTearDown(service.dispose);
    await Future.wait([
      service.updateProfile(name: '  Tên mới  ', bio: ' Giới thiệu mới '),
      service.setShowBio(false),
    ]);
    final account = await service.fetchAccount();
    expect(account.name, 'Tên mới');
    expect(account.bio, 'Giới thiệu mới');
    expect(account.showBio, isFalse);
    expect(
      () => service.updateProfile(name: ' ', bio: ''),
      throwsFormatException,
    );
    expect((await service.fetchProfile()).account, account);
  });
}
