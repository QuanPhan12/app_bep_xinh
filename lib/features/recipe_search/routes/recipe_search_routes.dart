import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';

import '../models/recipe_search_request.dart';
import '../screens/recipe_search_screen.dart';

GoRoute recipeSearchRoute() => GoRoute(
  path: PathRouter.recipeSearchScreen,
  name: NameRouter.recipeSearchScreen,
  builder: (_, state) => RecipeSearchScreen(
    initialRequest: RecipeSearchRequest(
      query: state.uri.queryParameters['q'] ?? '',
      filter: RecipeSearchFilter.fromId(state.uri.queryParameters['filter']),
    ),
  ),
);
