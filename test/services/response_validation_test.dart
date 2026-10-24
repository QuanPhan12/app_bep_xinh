import 'package:app_bep_xinh/features/ingredients/models/ingredient_catalog.dart';
import 'package:app_bep_xinh/features/fridge/models/fridge_data.dart';
import 'package:app_bep_xinh/features/fridge/models/fridge_recipe.dart';
import 'package:app_bep_xinh/features/home/models/home_data.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mock_services.dart';

void main() {
  test('rejects duplicate ids and invalid ingredient references', () {
    final fridge = fixtureJson('ingredients');
    final ingredients = fridge['ingredients'] as List;
    ingredients.add(ingredients.first);
    expect(() => IngredientCatalog.fromJson(fridge), throwsFormatException);
    final unknown = fixtureJson('fridge');
    (unknown['recipes'] as List).first['ingredientIds'] = ['unknown'];
    expect(
      () => FridgeData.fromJson(
        unknown,
        ingredients: catalogFixture().ingredients,
      ),
      throwsFormatException,
    );
    final home = fixtureJson('home');
    final banners = home['banners'] as List;
    banners.add(banners.first);
    expect(
      () => HomeData.fromJson(home, homeFixture().fridgeSummary),
      throwsFormatException,
    );
  });

  test(
    'rejects malformed lists, missing labels and impossible recipe values',
    () {
      final recipe = Map<String, dynamic>.from(
        (fixtureJson('home')['recipes'] as List).first,
      );
      for (final invalid in [double.nan, double.infinity, -1, 6]) {
        expect(
          () => RecipeItem.fromJson({...recipe, 'rating': invalid}),
          throwsFormatException,
        );
      }
      expect(
        () => RecipeItem.fromJson({...recipe, 'title': '  '}),
        throwsFormatException,
      );
      final fridge = fixtureJson('ingredients');
      fridge['ingredients'] = ['unexpected'];
      expect(() => IngredientCatalog.fromJson(fridge), throwsFormatException);
      final entry = Map<String, dynamic>.from(
        (fixtureJson('fridge')['recipes'] as List).first,
      );
      expect(
        () => FridgeRecipe.fromJson({...entry, 'minutes': -1}),
        throwsFormatException,
      );
      expect(
        () => FridgeRecipe.fromJson({...entry, 'ingredientIds': []}),
        throwsFormatException,
      );
    },
  );

  test(
    'response collections and parsed recipe ingredients cannot be mutated',
    () {
      final data = fridgeFixture();
      expect(() => data.selectedIds.add('beef'), throwsUnsupportedError);
      expect(
        () => data.recipes.first.ingredientIds.clear(),
        throwsUnsupportedError,
      );
      expect(() => data.ingredientsById.clear(), throwsUnsupportedError);
      expect(() => homeFixture().banners.clear(), throwsUnsupportedError);
    },
  );
}
