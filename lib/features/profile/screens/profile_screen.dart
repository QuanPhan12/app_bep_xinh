import 'package:app_bep_xinh/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';

import 'views/profile_mobile_view.dart';
import 'views/profile_tablet_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: ProfileMobileView(),
      tablet: ProfileTabletView(),
    );
  }
}
