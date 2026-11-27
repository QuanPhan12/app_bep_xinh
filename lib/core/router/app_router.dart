import '../../features/auth/services/auth_service.dart';
import '../../features/settings/screens/legal_screen.dart';
import '../../features/kitchen/screens/kitchen_hub_screen.dart';
import '../../features/meal_planner/screens/meal_planner_screen.dart';
import '../../features/pantry/screens/pantry_screen.dart';
import '../../features/recipe_collections/screens/recipe_collections_screen.dart';
import '../../features/cooking_journal/screens/cooking_journal_screen.dart';
import '../../features/cooking_timers/screens/cooking_timers_screen.dart';
import '../../features/offline_recipes/screens/offline_recipes_screen.dart';
import '../../features/following/screens/following_screen.dart';
import '../../features/recipe_reviews/screens/recipe_reviews_screen.dart';
import '../../features/auth/models/account_access.dart';
import '../../features/auth/screens/account_access_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/messages/routes/message_routes.dart';
import '../../features/recipe_editor/screens/recipe_submissions_screen.dart';

import 'package:app_bep_xinh/features/recipe_search/models/recipe_search_request.dart';
import 'package:app_bep_xinh/features/recipe_search/routes/recipe_search_routes.dart';
import 'package:app_bep_xinh/features/auth/screens/forgot_password/forgot_password_screen.dart';
import 'package:app_bep_xinh/features/auth/screens/login/login_screen.dart';
import 'package:app_bep_xinh/features/auth/screens/register/register_screen.dart';
import 'package:app_bep_xinh/features/cart/screens/cart_screen.dart';
import 'package:app_bep_xinh/features/fridge/screens/fridge_screen.dart';
import 'package:app_bep_xinh/features/home/screens/home_screen.dart';
import 'package:app_bep_xinh/features/navigation/screens/navigation_screen.dart';
import 'package:app_bep_xinh/features/profile/routes/profile_routes.dart';
import 'package:app_bep_xinh/features/settings/routes/settings_routes.dart';
import 'package:app_bep_xinh/features/recipe_detail/screens/recipe_detail_screen.dart';
import 'package:app_bep_xinh/features/recipe_editor/screens/recipe_editor_screen.dart';
import 'package:go_router/go_router.dart';

class PathRouter {
  const PathRouter._();
  static const loginScreen = "/login";
  static const registerScreen = "/register";
  static const forgotPasswordScreen = "/forgot-password";
  static const accountAccessScreen = '/account-access';
  static const homeScreen = "/home";
  static const fridgeScreen = "/fridge";
  static const cartScreen = "/cart";
  static const profileScreen = "/profile";
  static const profileEditScreen = '/profile/edit';
  static const recipeSubmissionsScreen = '/profile/submissions';
  static const publicProfileScreen = '/users/:userId';
  static const settingsScreen = '/settings';
  static const recipeDetailScreen = "/recipe/:id";
  static const recipeSearchScreen = '/recipes/search';
  static const recipeEditorScreen = '/recipes/new';
  static const notificationsScreen = '/notifications';
  static const messagesScreen = '/messages';
  static const newMessageScreen = '/messages/new';
  static String conversation(String id) =>
      '/messages/${Uri.encodeComponent(id)}';

  static String recipeSearch({
    RecipeSearchFilter filter = RecipeSearchFilter.all,
    String query = '',
    int? maxMinutes,
    RecipeDifficulty? difficulty,
    String excludedIngredients = '',
  }) =>
      filter == RecipeSearchFilter.all &&
          query.isEmpty &&
          maxMinutes == null &&
          difficulty == null &&
          excludedIngredients.isEmpty
      ? recipeSearchScreen
      : Uri(
          path: recipeSearchScreen,
          queryParameters: {
            if (filter != RecipeSearchFilter.all) 'filter': filter.id,
            if (query.isNotEmpty) 'q': query,
            if (maxMinutes != null) 'minutes': '$maxMinutes',
            if (difficulty != null) 'difficulty': difficulty.name,
            if (excludedIngredients.isNotEmpty) 'exclude': excludedIngredients,
          },
        ).toString();

  static String recipeDetail(String id) => '/recipe/${Uri.encodeComponent(id)}';
  static String publicProfile(String id) => '/users/${Uri.encodeComponent(id)}';
}

class NameRouter {
  const NameRouter._();
  static const loginScreen = "login_screen";
  static const registerScreen = "register_screen";
  static const forgotPasswordScreen = "forgot_password_screen";
  static const homeScreen = "home_screen";
  static const fridgeScreen = "fridge_screen";
  static const cartScreen = "cart_screen";
  static const profileScreen = "profile_screen";
  static const profileEditScreen = 'profile_edit_screen';
  static const publicProfileScreen = 'public_profile_screen';
  static const settingsScreen = 'settings_screen';
  static const recipeDetailScreen = "recipe_detail_screen";
  static const recipeSearchScreen = 'recipe_search_screen';
  static const recipeEditorScreen = 'recipe_editor_screen';
}

final appRouter = createAppRouter();

GoRouter createAppRouter({AuthService? auth}) => GoRouter(
  refreshListenable: auth?.sessionChanges,
  redirect: (context, state) =>
      auth == null ? null : authRedirect(auth, state.uri),
  initialLocation: PathRouter.loginScreen,
  routes: [
    GoRoute(path: '/legal/terms', builder: (_, _) => const LegalScreen()),
    GoRoute(
      path: '/legal/privacy',
      builder: (_, _) => const LegalScreen(privacy: true),
    ),
    GoRoute(
      path: PathRouter.cartScreen,
      name: NameRouter.cartScreen,
      builder: (_, _) => const CartScreen(),
    ),
    GoRoute(
      path: '/kitchen/meal-plan',
      builder: (_, _) => const MealPlannerScreen(),
    ),
    GoRoute(path: '/kitchen/pantry', builder: (_, _) => const PantryScreen()),
    GoRoute(
      path: '/kitchen/collections',
      builder: (_, _) => const RecipeCollectionsScreen(),
    ),
    GoRoute(
      path: '/kitchen/collections/:id',
      builder: (_, state) =>
          RecipeCollectionDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/kitchen/journal',
      builder: (_, _) => const CookingJournalScreen(),
    ),
    GoRoute(
      path: '/kitchen/timers',
      builder: (_, _) => const CookingTimersScreen(),
    ),
    GoRoute(
      path: '/kitchen/offline',
      builder: (_, _) => const OfflineRecipesScreen(),
    ),
    GoRoute(
      path: '/kitchen/offline/:id',
      builder: (_, state) =>
          OfflineRecipeScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/kitchen/following',
      builder: (_, _) => const FollowingScreen(),
    ),
    GoRoute(
      path: '/kitchen/following/feed',
      builder: (_, _) => const FollowingFeedScreen(),
    ),
    GoRoute(
      path: '/recipe/:id/reviews',
      builder: (_, state) =>
          RecipeReviewsScreen(recipeId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: PathRouter.accountAccessScreen,
      builder: (_, _) => const AccountAccessScreen(),
    ),
    GoRoute(
      path: PathRouter.notificationsScreen,
      builder: (_, _) => const NotificationsScreen(),
    ),
    ...messageRoutes(),
    GoRoute(
      path: PathRouter.recipeSubmissionsScreen,
      builder: (_, _) => const RecipeSubmissionsScreen(),
    ),
    recipeSearchRoute(),
    settingsRoute(),
    profileEditRoute(),
    publicProfileRoute(),
    GoRoute(
      path: PathRouter.loginScreen,
      name: NameRouter.loginScreen,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: PathRouter.registerScreen,
      name: NameRouter.registerScreen,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: PathRouter.forgotPasswordScreen,
      name: NameRouter.forgotPasswordScreen,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: PathRouter.recipeDetailScreen,
      name: NameRouter.recipeDetailScreen,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return RecipeDetailScreen(recipeId: id);
      },
    ),
    GoRoute(
      path: PathRouter.recipeEditorScreen,
      name: NameRouter.recipeEditorScreen,
      builder: (context, state) =>
          RecipeEditorScreen(remixRecipeId: state.uri.queryParameters['remix']),
    ),

    // StatefulShellRoute quản lý cấu trúc Shell với BottomBar và các branches
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return NavigationScreen(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: Trang chủ
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: PathRouter.homeScreen,
              name: NameRouter.homeScreen,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Branch 1: Tủ lạnh thông minh
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: PathRouter.fridgeScreen,
              name: NameRouter.fridgeScreen,
              builder: (context, state) => const FridgeScreen(),
            ),
          ],
        ),

        // Branch 2: Bếp cá nhân, giữ nguyên stack khi đổi tab.
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/kitchen',
              builder: (context, state) =>
                  const KitchenHubScreen(embedded: true),
            ),
          ],
        ),

        // Branch 3: Cá nhân
        StatefulShellBranch(routes: [profileRoute()]),
      ],
    ),
  ],
);

String? authRedirect(AuthService auth, Uri uri) {
  final path = uri.path;
  const authPaths = {
    PathRouter.loginScreen,
    PathRouter.registerScreen,
    PathRouter.forgotPasswordScreen,
  };
  if (path == '/legal/terms' || path == '/legal/privacy') return null;
  if (auth is AccountSessionAccess) {
    final access = (auth as AccountSessionAccess).accountAccess;
    // Form giữ trạng thái loading trong lúc xác minh, tránh chớp sang màn kiểm tra.
    // UID vẫn chưa được mở nên các route nội dung tiếp tục bị chặn.
    if (access.status == AccountAccessStatus.checking &&
        authPaths.contains(path)) {
      return null;
    }
    final blocked =
        access.status != AccountAccessStatus.active &&
        access.status != AccountAccessStatus.signedOut;
    if (blocked) {
      if (path == PathRouter.accountAccessScreen) return null;
      return Uri(
        path: PathRouter.accountAccessScreen,
        queryParameters: {'from': uri.toString()},
      ).toString();
    }
  }
  if (path == PathRouter.accountAccessScreen) {
    return auth.userId == null
        ? PathRouter.loginScreen
        : Uri(
            path: PathRouter.loginScreen,
            queryParameters: {'from': uri.queryParameters['from'] ?? ''},
          ).toString();
  }
  final privatePage =
      path == '/kitchen' ||
      path.startsWith('/kitchen/') ||
      path == PathRouter.fridgeScreen ||
      path == PathRouter.cartScreen ||
      path == PathRouter.profileScreen ||
      path.startsWith('/profile/') ||
      path == PathRouter.settingsScreen ||
      path.startsWith('${PathRouter.settingsScreen}/') ||
      path == PathRouter.recipeEditorScreen ||
      path == PathRouter.notificationsScreen ||
      path == PathRouter.messagesScreen ||
      path.startsWith('${PathRouter.messagesScreen}/');
  if (auth.userId == null && privatePage) {
    return Uri(
      path: PathRouter.loginScreen,
      queryParameters: {'from': uri.toString()},
    ).toString();
  }
  if (auth.userId != null && authPaths.contains(path)) {
    final from = Uri.tryParse(uri.queryParameters['from'] ?? '');
    if (from != null &&
        !from.hasScheme &&
        !from.hasAuthority &&
        from.path.startsWith('/') &&
        !authPaths.contains(from.path)) {
      return from.toString();
    }
    return PathRouter.homeScreen;
  }
  return null;
}
