import 'package:app_bep_xinh/features/auth/screens/login/login_screen.dart';
import 'package:app_bep_xinh/features/auth/screens/register/register_screen.dart';
import 'package:go_router/go_router.dart';

class PathRouter {
  const PathRouter._();
  static const loginScreen = "/login";
  static const registerScreen = "/register";
}

class NameRouter {
  const NameRouter._();
  static const loginScreen = "login_screen";
  static const registerScreen = "register_screen";
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
  ],
);
