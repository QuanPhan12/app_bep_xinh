import '../../recipes/models/recipe_remix.dart';
import '../../../core/services/json_reader.dart';
import '../../ingredients/models/ingredient_catalog.dart';
import '../models/recipe_draft.dart';

abstract final class RecipeDraftCodec {
  static Map<String, dynamic> encode(RecipeDraft draft) => {
    if (draft.remix != null) 'remix': draft.remix!.toJson(),
    if (draft.remixBaseline != null) 'remixBaseline': draft.remixBaseline,
    'title': draft.title,
    'cover': draft.cover?.toJson(),
    if (draft.photos.isNotEmpty)
      'photos': draft.photos.map((image) => image.toJson()).toList(),
    'description': draft.description,
    'preparationMinutes': draft.preparationMinutes,
    'cookingMinutes': draft.cookingMinutes,
    'servings': draft.servings,
    'difficulty': draft.difficulty.name,
    'storageNotes': draft.storageNotes,
    'meals': draft.meals.map((e) => e.name).toList(),
    'categories': draft.categories.map((e) => e.id).toList(),
    'ingredientGroups': draft.ingredientGroups.map((e) => e.toJson()).toList(),
    'ingredients': draft.ingredients
        .map((e) => {'id': e.id, ...e.toJson()})
        .toList(),
    'steps': draft.steps
        .map(
          (e) => {
            'id': e.id,
            'instruction': e.instruction,
            'title': e.title,
            'minutes': e.minutes,
            'tip': e.tip,
            'photo': e.photo?.toJson(),
          },
        )
        .toList(),
  };

  static RecipeDraft decode(
    Map<String, dynamic> json,
    IngredientCatalog catalog,
  ) {
    final r = JsonReader(json);
    RecipeImage? image(Object? value) => value == null
        ? null
        : RecipeImage.fromJson(value as Map<String, dynamic>);
    return RecipeDraft(
      remix: json['remix'] == null
          ? null
          : RecipeRemix.fromJson(
              Map<String, dynamic>.from(json['remix'] as Map),
            ),
      remixBaseline: r.optionalString('remixBaseline'),
      title: r.string('title', allowEmpty: true),
      cover: image(json['cover']),
      photos: decodeRecipePhotos(json['photos']),
      description: r.string('description', allowEmpty: true),
      preparationMinutes: r.string('preparationMinutes', allowEmpty: true),
      cookingMinutes: r.string('cookingMinutes', allowEmpty: true),
      servings: r.integer('servings', min: 1),
      difficulty: RecipeDifficulty.parse(r.string('difficulty')),
      storageNotes: r.string('storageNotes', allowEmpty: true),
      meals: r.strings('meals').map((e) => RecipeMeal.values.byName(e)).toSet(),
      categories: r.strings('categories').map(RecipeCategory.parse).toSet(),
      ingredientGroups: r
          .objects('ingredientGroups')
          .map(RecipeIngredientGroup.fromJson)
          .toList(),
      ingredients: r.objects('ingredients').map((e) {
        final i = JsonReader(e);
        return RecipeIngredientDraft(
          id: i.string('id'),
          ingredientId: i.optionalString('ingredientId'),
          name: i.string('name'),
          amount: e['amount'] == null ? null : i.number('amount'),
          unit: catalog.unitsById[i.optionalString('unitId')],
          toTaste: i.boolean('toTaste'),
          note: i.string('note', allowEmpty: true),
          groupId: i.string('groupId'),
        );
      }).toList(),
      steps: r.objects('steps').map((e) {
        final s = JsonReader(e);
        return RecipeStepDraft(
          id: s.string('id'),
          instruction: s.string('instruction', allowEmpty: true),
          title: s.string('title', allowEmpty: true),
          minutes: s.string('minutes', allowEmpty: true),
          tip: s.string('tip', allowEmpty: true),
          photo: image(e['photo']),
        );
      }).toList(),
    );
  }
}
