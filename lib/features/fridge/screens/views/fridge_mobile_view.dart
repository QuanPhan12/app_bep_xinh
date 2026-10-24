import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

import '../../widgets/fridge_content.dart';

class FridgeMobileView extends StatelessWidget {
  const FridgeMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxContentWidth,
            ),
            child: const FridgeContent(),
          ),
        ),
      ),
    );
  }
}
