import 'package:flutter/material.dart';

import '../../../../../core/colors/app_colors.dart';
import '../../../../../core/dimensions/dimensions.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../widgets/forgot_password_form.dart';

class ForgotPasswordMobileView extends StatelessWidget {
  const ForgotPasswordMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = context.appSize;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          const AppSliverAppBar(title: 'Quên mật khẩu', pinned: true),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: size.space16.w(context),
              vertical: size.space16.h(context),
            ),
            sliver: const SliverToBoxAdapter(child: ForgotPasswordForm()),
          ),
        ],
      ),
    );
  }
}
