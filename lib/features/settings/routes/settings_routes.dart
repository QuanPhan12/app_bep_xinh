import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';

import '../screens/settings_screen.dart';

GoRoute settingsRoute() => GoRoute(
  path: PathRouter.settingsScreen,
  name: NameRouter.settingsScreen,
  builder: (_, _) => const SettingsScreen(),
);
