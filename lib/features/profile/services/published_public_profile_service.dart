import '../../home/models/recipe_item.dart';
import '../../recipes/models/recipe_author.dart';
import '../../recipes/services/published_recipe_source.dart';
import '../../recipes/services/recipe_favorites_service.dart';
import '../models/public_profile_data.dart';
import 'public_profile_service.dart';

/// Hồ sơ tác giả công khai chỉ lấy danh tính đi kèm công thức đã được duyệt.
class PublishedPublicProfileService implements PublicProfileService {
  final PublicProfileService bundled;
  final PublishedRecipeSource source;
  final RecipeFavoritesService favorites;
  PublishedPublicProfileService({
    required this.bundled,
    required this.source,
    required this.favorites,
  });
  @override
  Stream<PublicProfileUser> get publicChanges => bundled.publicChanges;
  @override
  Future<PublicProfileData> fetchPublicProfile(String userId) async {
    final records = await source.forAuthor(userId);
    if (records.isEmpty) return bundled.fetchPublicProfile(userId);
    final recipes = await Future.wait(
      records.map(
        (json) async => RecipeItem.fromRecipeJson(
          json,
          isFavorite: await favorites.isFavorite(
            json['id'] as String,
            fallback: false,
          ),
        ),
      ),
    );
    return PublicProfileData(
      user: PublicProfileUser(
        identity: RecipeAuthor.read(records.first['author']),
      ),
      recipes: recipes,
    );
  }
}
