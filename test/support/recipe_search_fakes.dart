import 'package:app_bep_xinh/features/home/models/recipe_item.dart';
import 'package:app_bep_xinh/features/recipe_search/models/recipe_search_request.dart';
import 'package:app_bep_xinh/features/recipe_search/services/recipe_search_service.dart';

import 'mock_services.dart';

class StubRecipeSearchService implements RecipeSearchService {
  final requests = <RecipeSearchRequest>[];
  Future<List<RecipeItem>> Function(RecipeSearchRequest)? onSearch;
  @override
  Future<List<RecipeItem>> search(RecipeSearchRequest request) {
    requests.add(request);
    return onSearch?.call(request) ?? Future.value(homeFixture().recipes);
  }
}
