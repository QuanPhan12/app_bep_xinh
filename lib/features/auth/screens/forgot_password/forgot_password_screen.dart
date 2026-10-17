import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/responsive_layout.dart';
import '../../cubits/forgot_password/forgot_password_cubit.dart';
import 'views/forgot_password_mobile_view.dart';
import 'views/forgot_password_tablet_view.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForgotPasswordCubit(),
      child: const ResponsiveLayout(
        mobile: ForgotPasswordMobileView(),
        tablet: ForgotPasswordTabletView(),
      ),
    );
  }
}
