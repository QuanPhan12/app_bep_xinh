/// Only author-selected classifications. Newest/all are discovery filters.
enum RecipeCategory {
  eatClean('eat_clean'),
  quick('quick'),
  soup('soup'),
  vegetarian('vegetarian');

  final String id;
  const RecipeCategory(this.id);

  static RecipeCategory parse(String id) =>
      values.where((value) => value.id == id).firstOrNull ??
      (throw const FormatException('Invalid recipe category'));
}
