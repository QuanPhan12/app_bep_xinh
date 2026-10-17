import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/constants/app_constants.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/widgets/app_sliver_app_bar.dart';
import 'package:app_bep_xinh/features/auth/widgets/register_form.dart';
import 'package:flutter/material.dart';

class RegisterTabletView extends StatelessWidget {
  const RegisterTabletView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = context.appSize;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          const AppSliverAppBar(title: 'Đăng ký tài khoản', pinned: true),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: size.space24.w(context),
              vertical: size.space24.w(context),
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.maxContentWidth,
                  ),
                  child: RegisterForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
