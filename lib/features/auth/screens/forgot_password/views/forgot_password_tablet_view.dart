import 'package:flutter/material.dart';

import '../../../../../core/colors/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/dimensions/dimensions.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../widgets/forgot_password_form.dart';

class ForgotPasswordTabletView extends StatelessWidget {
  const ForgotPasswordTabletView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = context.appSize;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          const AppSliverAppBar(
            title: 'Quên mật khẩu',
            pinned: true,
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: size.space24.w(context),
              vertical: size.space32.h(context),
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.maxContentWidth,
                  ),
                  child: const ForgotPasswordForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
