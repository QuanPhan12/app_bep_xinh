import 'dart:convert';

import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/recipe_detail/models/recipe_detail.dart';
import 'package:app_bep_xinh/features/recipe_detail/services/recipe_detail_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_editor_service.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_services.dart';
import '../../support/recipe_editor_fakes.dart';

void main() {
  test('complete form round trips to detail without losing groups, ordering, photos or notes', () {
    final draft = richRecipeDraft();
    final content = draft.toRecipeContent();
    final json =
        jsonDecode(jsonEncode(content.toJson())) as Map<String, dynamic>;
    final detail = RecipeDetail.fromJson({
      ...json,
      'id': 'authored_recipe',
      'author': 'Tác giả',
    }, catalogFixture());
    expect(detail.content, content);
    expect(detail.content.categories, {RecipeCategory.vegetarian});
    expect(() => detail.content.categories.clear(), throwsUnsupportedError);
    expect(detail.ingredientGroups.map((group) => group.id), ['sauce', 'main']);
    expect(detail.ingredients.map((item) => item.id), [
      'ingredient_0',
      'spice_0',
    ]);
    expect(detail.ingredients.last.groupId, 'sauce');
    expect(detail.ingredients.last.quantity(3), 'Vừa đủ');
    expect(detail.steps.map((step) => step.id), ['step_later', 'step_0']);
    expect(detail.steps.first.minutes, 5);
    expect(detail.steps.last.tip, 'Giữ lửa vừa.');
    expect(detail.steps.first.photo!.bytes, draft.steps.first.photo!.bytes);
    expect(detail.cover!.bytes, draft.cover!.bytes);
    expect(detail.meals, {RecipeMeal.lunch, RecipeMeal.weekend});
    expect(detail.storageNotes, draft.storageNotes);
    expect(() => detail.ingredientGroups.clear(), throwsUnsupportedError);
    expect(
      () => detail.steps.first.photo!.bytes![0] = 0,
      throwsUnsupportedError,
    );
  });

  test('submission keeps the canonical pending content and does not publish it into public detail', () async {
    final api = fixtureApi();
    final catalog = MockIngredientCatalogService(api);
    final editor = MockRecipeEditorService(api, catalog);
    final draft = richRecipeDraft();
    await editor.saveDraft(draft);
    await editor.submit(draft);
    expect(editor.lastSubmittedContent, draft.toRecipeContent());
    expect(await editor.loadDraft(), isNull);
    final favorites = MockRecipeFavoritesService(api);
    final fridge = createMockFridgeService();
    addTearDown(favorites.dispose);
    addTearDown(fridge.dispose);
    final detail = MockRecipeDetailService(api, catalog, fridge, favorites);
    await expectLater(
      detail.fetchRecipe('authored_recipe'),
      throwsA(isA<RecipeNotFoundException>()),
    );
    final invalid = draft.copyWith(
      ingredientGroups: const [
        RecipeIngredientGroup(id: 'main', name: 'Chính'),
      ],
    );
    await expectLater(editor.submit(invalid), throwsFormatException);
    expect(editor.lastSubmittedContent, draft.toRecipeContent());
  });

  test(
    'optional editor fields stay optional and legacy recipes remain readable',
    () {
      final json = validRecipeDraft().toRecipeContent().toJson();
      expect(RecipeContent.fromJson(json, catalogFixture()).description, '');
      expect(
        RecipeContent.fromJson(json, catalogFixture()).steps.single.minutes,
        isNull,
      );
      final legacy = <String, dynamic>{...json}
        ..remove('cover')
        ..remove('ingredientGroups')
        ..remove('meals')
        ..remove('storageNotes');
      legacy['image'] = 'assets/images/bo_ne.jpg';
      legacy['difficulty'] = 'Dễ làm';
      legacy['ingredients'] = (json['ingredients'] as List)
          .map((item) => {...item as Map<String, dynamic>}..remove('groupId'))
          .toList();
      legacy['steps'] = [
        {'id': 'old_step', 'instruction': 'Nấu chín.'},
      ];
      final parsed = RecipeContent.fromJson(legacy, catalogFixture());
      expect(parsed.ingredientGroups.single.id, 'main');
      expect(parsed.cover!.assetPath, 'assets/images/bo_ne.jpg');
      expect(parsed.steps.single.photo, isNull);
      expect(parsed.difficulty, RecipeDifficulty.easy);
    },
  );

  test('reader rejects mismatched group ids, invalid steps, duplicate ingredients and invalid new fields', () {
    final json = richRecipeDraft().toRecipeContent().toJson();
    final firstIngredient =
        (json['ingredients'] as List).first as Map<String, dynamic>;
    final firstStep = (json['steps'] as List).first as Map<String, dynamic>;
    for (final invalid in <Map<String, dynamic>>[
      {...json, 'ingredientGroups': []},
      {
        ...json,
        'ingredientGroups': [
          json['ingredientGroups'][0],
          json['ingredientGroups'][0],
        ],
      },
      {
        ...json,
        'ingredients': [
          {...firstIngredient, 'groupId': 'missing'},
        ],
      },
      {
        ...json,
        'ingredients': [
          firstIngredient,
          {...firstIngredient, 'id': 'another_row'},
        ],
      },
      {
        ...json,
        'steps': [
          {...firstStep, 'minutes': 0},
        ],
      },
      {
        ...json,
        'steps': [
          {...firstStep, 'minutes': 721},
        ],
      },
      {
        ...json,
        'steps': [
          {
            ...firstStep,
            'photo': {'id': 'bad'},
          },
        ],
      },
      {
        ...json,
        'meals': ['unknown'],
      },
      {...json, 'storageNotes': 'a' * 501},
    ]) {
      expect(
        () => RecipeContent.fromJson(invalid, catalogFixture()),
        throwsFormatException,
      );
    }
  });

  test(
    'memory and bundled images round trip with one source and immutable bytes',
    () {
      final memory = recipeCoverFixture();
      final decoded = RecipeImage.fromJson(memory.toJson());
      expect(decoded, memory);
      expect(decoded.bytes, memory.bytes);
      final asset = RecipeImage.asset(
        id: 'asset',
        assetPath: 'assets/images/bo_ne.jpg',
      );
      expect(RecipeImage.fromJson(asset.toJson()), asset);
      expect(
        () => RecipeImage.fromJson({
          'id': 'bad',
          'bytesBase64': '!',
          'assetPath': 'asset',
        }),
        throwsFormatException,
      );
      expect(
        () => RecipeImage.fromJson({'id': 'bad', 'bytesBase64': ''}),
        throwsFormatException,
      );
    },
  );
}
