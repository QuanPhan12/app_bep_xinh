import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';

import '../screens/profile_screen.dart';
import '../screens/profile_edit_screen.dart';
import '../screens/public_profile_screen.dart';

GoRoute profileRoute() => GoRoute(
  path: PathRouter.profileScreen,
  name: NameRouter.profileScreen,
  builder: (_, state) =>
      ProfileScreen(showSaved: state.uri.queryParameters['tab'] == 'saved'),
);

GoRoute publicProfileRoute() => GoRoute(
  path: PathRouter.publicProfileScreen,
  name: NameRouter.publicProfileScreen,
  builder: (_, state) =>
      PublicProfileScreen(userId: state.pathParameters['userId']!),
);

GoRoute profileEditRoute() => GoRoute(
  path: PathRouter.profileEditScreen,
  name: NameRouter.profileEditScreen,
  builder: (_, _) => const ProfileEditScreen(),
);
