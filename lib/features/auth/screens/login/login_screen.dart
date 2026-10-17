import 'package:app_bep_xinh/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/login/login_cubit.dart';
import 'views/login_mobile_view.dart';
import 'views/login_tablet_view.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: const ResponsiveLayout(
        mobile: LoginMobileView(),
        tablet: LoginTabletView(),
      ),
    );
  }
}
