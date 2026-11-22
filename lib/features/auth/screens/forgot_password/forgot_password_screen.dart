import '../../services/auth_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/forgot_password/forgot_password_cubit.dart';
import 'views/forgot_password_mobile_view.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ForgotPasswordCubit(service: context.read<AuthService>()),
      child: const ForgotPasswordMobileView(),
    );
  }
}
