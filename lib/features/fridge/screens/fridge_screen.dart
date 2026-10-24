import 'package:app_bep_xinh/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';

import 'views/fridge_mobile_view.dart';
import 'views/fridge_tablet_view.dart';

class FridgeScreen extends StatelessWidget {
  const FridgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: FridgeMobileView(),
      tablet: FridgeTabletView(),
    );
  }
}
