import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:app_bep_xinh/core/dimensions/dimensions.dart';
import 'package:app_bep_xinh/core/widgets/widgets.dart';
import 'package:app_bep_xinh/features/auth/widgets/register_form.dart';
import 'package:flutter/material.dart';

class RegisterMobileView extends StatelessWidget {
  const RegisterMobileView({super.key});

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
              horizontal: size.space16.w(context),
              vertical: size.space16.w(context),
            ),
            sliver: const SliverToBoxAdapter(child: RegisterForm()),
          ),
        ],
      ),
    );
  }
}
