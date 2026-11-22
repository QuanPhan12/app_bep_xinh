import 'package:app_bep_xinh/features/auth/widgets/login_logo.dart';
import 'package:flutter/material.dart';

import '../../../../../core/colors/app_colors.dart';
import '../../../../../core/dimensions/dimensions.dart';
import '../../../widgets/login_form.dart';
import '../../../widgets/auth_content_width.dart';
import '../../../../../core/text_styles/app_text_styles.dart';

class LoginMobileView extends StatelessWidget {
  const LoginMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = context.appSize;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // const AppSliverAppBar(
              //   title: 'Đăng nhập',
              //   automaticallyImplyLeading: false,
              // ),
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.space16.w(context),
                      vertical: size.space16.w(context),
                    ),
                    child: AuthContentWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo & Tiêu đề
                          const LoginLogo(),
                          const SizedBox(height: 20),
                          Text(
                            'Đăng nhập Bếp Xinh',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          // const SizedBox(height: 8),
                          // Text(
                          //   'Đăng nhập để lưu món ngon và chia sẻ công thức.',
                          //   style: AppTextStyles.bodyMedium.copyWith(
                          //     color: context.colors.textSecondary,
                          //     height: 1.5,
                          //   ),
                          //   textAlign: TextAlign.center,
                          // ),
                          SizedBox(height: 28.h(context)),
                          // Form đăng nhập dùng chung
                          const LoginForm(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
