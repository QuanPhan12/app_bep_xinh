import 'package:app_bep_xinh/features/fridge/cubits/fridge/fridge_state.dart';
import 'package:app_bep_xinh/features/fridge/services/fridge_inventory_repository.dart';
import 'package:app_bep_xinh/features/fridge/services/remote_fridge_service.dart';
import 'package:app_bep_xinh/features/ingredients/services/ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/models/recipe_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/mock_services.dart';
import '../../support/recipe_editor_fakes.dart';

class _Inventory implements FridgeInventoryRepository {
  List<String> ids = [];
  bool fail = false;
  @override
  Future<List<String>> read() async => [...ids];
  @override
  Future<void> save(List<String> ingredientIds) async {
    if (fail) throw StateError('Write denied');
    ids = [...ingredientIds];
  }
}

void main() {
  late _Inventory inventory;
  late List<Map<String, dynamic>> published;
  RemoteFridgeService create() {
    final service = RemoteFridgeService(
      inventory: inventory,
      catalog: MockIngredientCatalogService(fixtureApi()),
      readPublished: () async => published,
    );
    addTearDown(service.dispose);
    return service;
  }

  setUp(() {
    inventory = _Inventory();
    published = [
      {
        'id': 'r_approved',
        ...validRecipeDraft()
            .copyWith(
              cover: const RecipeImage.remote(
                id: 'cover',
                url: 'https://res.cloudinary.com/ddqouziau/image/upload/v1/food.jpg',
                publicId: 'food',
              ),
              categories: {RecipeCategory.vegetarian},
            )
            .toRecipeContent()
            .toJson(),
      },
    ];
  });

  test(
    'new account starts empty and suggestions use published photo and id',
    () async {
      final service = create();
      final data = await service.fetchFridge();
      expect(data.selectedIds, isEmpty);
      expect(data.recipes.single.id, 'r_approved');
      expect(data.recipes.single.image, contains('res.cloudinary.com'));
      expect(data.recipes.single.isVegetarian, isTrue);
      await service.saveInventory(['egg', 'egg']);
      final reopened = await create().fetchFridge();
      expect(reopened.selectedIds, ['egg']);
      expect(
        FridgeState(
          data: reopened,
          selectedIds: reopened.selectedIds,
        ).readyRecipes,
        hasLength(1),
      );
    },
  );

  test(
    'custom ingredient is missing and its name is shown rather than its id',
    () async {
      final ingredients = published.single['ingredients'] as List;
      ingredients.add(<String, dynamic>{
        ...ingredients.first as Map<String, dynamic>,
        'id': 'custom_row',
        'ingredientId': null,
        'name': 'Gia vị riêng',
      });
      inventory.ids = ['egg'];
      final data = await create().fetchFridge();
      final state = FridgeState(data: data, selectedIds: data.selectedIds);
      expect(state.readyRecipes, isEmpty);
      final missing = state.almostReadyRecipes.single
          .missingIngredients(state.selectedIds)
          .single;
      expect(state.ingredientName(missing), 'Gia vị riêng');
    },
  );

  test(
    'failed write keeps confirmed inventory; unknown ids never get written',
    () async {
      inventory.ids = ['egg'];
      final service = create();
      await service.fetchFridge();
      inventory.fail = true;
      await expectLater(service.saveInventory(['tomato']), throwsStateError);
      expect((await service.fetchFridge()).selectedIds, ['egg']);
      inventory.fail = false;
      await expectLater(
        service.saveInventory(['not_in_catalog']),
        throwsArgumentError,
      );
      expect(inventory.ids, ['egg']);
      await service.saveInventory([]);
      expect((await create().fetchFridge()).selectedIds, isEmpty);
    },
  );

  test(
    'empty public collection never falls back to local recipe fixtures',
    () async {
      published = [];
      inventory.ids = ['egg', 'old_catalog_id'];
      final data = await create().fetchFridge();
      expect(data.recipes, isEmpty);
      expect(data.selectedIds, ['egg']);
    },
  );
}
