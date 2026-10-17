import 'package:app_bep_xinh/core/constants/app_const.dart';
import 'package:app_bep_xinh/core/dimensions/app_size.dart';
import 'package:app_bep_xinh/core/text_styles/app_text_styles.dart';
import 'package:app_bep_xinh/features/auth/widgets/login_logo.dart';
import 'package:flutter/material.dart';

import '../../../../../core/colors/app_colors.dart';
import '../../../widgets/login_form.dart';

/// Giao diện đăng nhập dành riêng cho Tablet / Màn hình lớn (>= 600px):
/// Bố cục 2 cột (Split View):
/// - Cột bên trái (45%): Banner thương hiệu và giới thiệu tính năng ẩm thực.
/// - Cột bên phải (55%): Form đăng nhập được căn giữa với khung giới hạn maxWidth 440px.
class LoginTabletView extends StatelessWidget {
  const LoginTabletView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = context.appSize;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          // 1. CỘT BÊN TRÁI: Banner thương hiệu Bếp Xinh
          Expanded(
            flex: 5,
            child: Center(
              child: Text(
                'Bếp Xinh xin chào bạn',
                textAlign: TextAlign.center,
                style: AppTextStyles.displayMedium,
              ),
            ),
          ),

          // 2. CỘT BÊN PHẢI: Khung nhập liệu đăng nhập
          Expanded(
            flex: 6,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.space24.w(context),
                    vertical: size.space24.w(context),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppConst.maxContentWidth,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo & Tiêu đề
                        const LoginLogo(),
                        SizedBox(height: size.space32.h(context)),
                        // Form đăng nhập dùng chung
                        const LoginForm(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
