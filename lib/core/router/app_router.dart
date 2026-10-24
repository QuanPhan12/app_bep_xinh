import 'package:app_bep_xinh/features/auth/screens/forgot_password/forgot_password_screen.dart';
import 'package:app_bep_xinh/features/auth/screens/login/login_screen.dart';
import 'package:app_bep_xinh/features/auth/screens/register/register_screen.dart';
import 'package:app_bep_xinh/features/cart/screens/cart_screen.dart';
import 'package:app_bep_xinh/features/fridge/screens/fridge_screen.dart';
import 'package:app_bep_xinh/features/home/screens/home_screen.dart';
import 'package:app_bep_xinh/features/navigation/screens/navigation_screen.dart';
import 'package:app_bep_xinh/features/profile/screens/profile_screen.dart';
import 'package:app_bep_xinh/features/recipe_detail/screens/recipe_detail_screen.dart';
import 'package:app_bep_xinh/features/recipe_editor/screens/recipe_editor_screen.dart';
import 'package:go_router/go_router.dart';

class PathRouter {
  const PathRouter._();
  static const loginScreen = "/login";
  static const registerScreen = "/register";
  static const forgotPasswordScreen = "/forgot-password";
  static const homeScreen = "/home";
  static const fridgeScreen = "/fridge";
  static const cartScreen = "/cart";
  static const profileScreen = "/profile";
  static const recipeDetailScreen = "/recipe/:id";
  static const recipeEditorScreen = '/recipes/new';

  static String recipeDetail(String id) => "/recipe/$id";
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
  static const recipeDetailScreen = "recipe_detail_screen";
  static const recipeEditorScreen = 'recipe_editor_screen';
}

final appRouter = GoRouter(
  initialLocation: PathRouter.loginScreen,
  routes: [
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
        final id = state.pathParameters['id'] ?? 'bo_ne_tieu_den';
        return RecipeDetailScreen(recipeId: id);
      },
    ),
    GoRoute(
      path: PathRouter.recipeEditorScreen,
      name: NameRouter.recipeEditorScreen,
      builder: (context, state) => const RecipeEditorScreen(),
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

        // Branch 2: Giỏ đi chợ
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: PathRouter.cartScreen,
              name: NameRouter.cartScreen,
              builder: (context, state) => const CartScreen(),
            ),
          ],
        ),

        // Branch 3: Cá nhân
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: PathRouter.profileScreen,
              name: NameRouter.profileScreen,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
