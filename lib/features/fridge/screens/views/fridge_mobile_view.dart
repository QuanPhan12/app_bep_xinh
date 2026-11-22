import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:flutter/material.dart';

import '../../widgets/fridge_content.dart';

class FridgeMobileView extends StatelessWidget {
  const FridgeMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: const SafeArea(top: false, child: FridgeContent()),
    );
  }
}
