import 'package:app_bep_xinh/features/home/models/home_banner_item.dart';
import 'package:app_bep_xinh/features/recipe_editor/models/recipe_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_services.dart';
import '../../support/recipe_editor_fakes.dart';

void main() {
  test(
    'banner uses published recipe id, Cloudinary cover and total cooking time',
    () {
      final content = validRecipeDraft()
          .copyWith(
            preparationMinutes: '5',
            cookingMinutes: '10',
            cover: const RecipeImage.remote(
              id: 'cover',
              url: 'https://res.cloudinary.com/ddqouziau/image/upload/v1/banner.jpg',
              publicId: 'banner',
            ),
          )
          .toRecipeContent();
      final banner = HomeBannerItem.fromRecipeJson({
        'id': 'r_featured',
        ...content.toJson(),
        'isBanner': true,
      });
      expect(banner.id, 'r_featured');
      expect(banner.image, content.cover!.url);
      expect(banner.cookTime, '15 phút');
      expect(banner.title, content.title);
    },
  );

  test(
    'legacy recipe defaults banner off and author revision cannot enable it',
    () {
      final json = validRecipeDraft().toRecipeContent().toJson()
        ..remove('isBanner');
      expect(RecipeContent.fromJson(json, catalogFixture()).isBanner, isFalse);
      json['isBanner'] = true;
      final content = RecipeContent.fromJson(json, catalogFixture());
      expect(
        RecipeDraft.fromContent(content).toRecipeContent().isBanner,
        isFalse,
      );
      json['isBanner'] = 'true';
      expect(
        () => RecipeContent.fromJson(json, catalogFixture()),
        throwsFormatException,
      );
    },
  );
}
