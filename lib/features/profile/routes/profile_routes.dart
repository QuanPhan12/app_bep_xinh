import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';

import '../screens/profile_screen.dart';
import '../screens/public_profile_screen.dart';

GoRoute profileRoute() => GoRoute(
  path: PathRouter.profileScreen,
  name: NameRouter.profileScreen,
  builder: (_, _) => const ProfileScreen(),
);

GoRoute publicProfileRoute() => GoRoute(
  path: PathRouter.publicProfileScreen,
  name: NameRouter.publicProfileScreen,
  builder: (_, state) =>
      PublicProfileScreen(userId: state.pathParameters['userId']!),
);
