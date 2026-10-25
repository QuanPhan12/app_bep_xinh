import 'package:app_bep_xinh/features/auth/cubits/register/register_cubit.dart';
import 'package:app_bep_xinh/features/auth/screens/register/views/register_mobile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterCubit(),
      child: const RegisterMobileView(),
    );
  }
}
