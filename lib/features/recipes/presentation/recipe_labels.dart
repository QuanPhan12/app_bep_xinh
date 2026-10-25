import '../models/recipe_content.dart';

extension RecipeCategoryLabel on RecipeCategory {
  String get label => switch (this) {
    RecipeCategory.eatClean => 'Eat Clean',
    RecipeCategory.quick => 'Nấu nhanh',
    RecipeCategory.soup => 'Món nước',
    RecipeCategory.vegetarian => 'Món chay',
  };
}

extension RecipeDifficultyLabel on RecipeDifficulty {
  String get label => switch (this) {
    RecipeDifficulty.easy => 'Dễ làm',
    RecipeDifficulty.medium => 'Trung bình',
    RecipeDifficulty.hard => 'Công phu',
  };
}

extension RecipeMealLabel on RecipeMeal {
  String get label => switch (this) {
    RecipeMeal.breakfast => 'Bữa sáng',
    RecipeMeal.lunch => 'Bữa trưa',
    RecipeMeal.dinner => 'Bữa tối',
    RecipeMeal.snack => 'Ăn vặt',
    RecipeMeal.gathering => 'Tiệc gia đình',
    RecipeMeal.weekend => 'Cuối tuần',
  };
}
