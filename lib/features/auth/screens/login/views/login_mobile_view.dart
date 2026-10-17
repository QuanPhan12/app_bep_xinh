import 'package:app_bep_xinh/features/auth/widgets/login_logo.dart';
import 'package:flutter/material.dart';

import '../../../../../core/colors/app_colors.dart';
import '../../../../../core/dimensions/dimensions.dart';
import '../../../widgets/login_form.dart';

class LoginMobileView extends StatelessWidget {
  const LoginMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = context.appSize;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.space16.w(context),
              vertical: size.space16.w(context),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Tiêu đề
                const LoginLogo(),
                SizedBox(height: 28.h(context)),
                // Form đăng nhập dùng chung
                const LoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
