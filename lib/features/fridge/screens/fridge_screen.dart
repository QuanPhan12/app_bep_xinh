import '../widgets/fridge_skeleton.dart';

import 'package:app_bep_xinh/core/widgets/responsive_layout.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/fridge/fridge_cubit.dart';
import '../services/fridge_service.dart';

import 'views/fridge_mobile_view.dart';
import 'views/fridge_tablet_view.dart';

class FridgeScreen extends StatelessWidget {
  const FridgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          FridgeCubit(service: context.read<FridgeService>())..loadFridge(),
      child: BlocConsumer<FridgeCubit, FridgeState>(
        buildWhen: (previous, current) =>
            previous.hasCatalog != current.hasCatalog || !current.hasCatalog,
        listenWhen: (previous, current) =>
            current.hasCatalog &&
            current.errorMessage != null &&
            previous.errorMessage != current.errorMessage,
        listener: (context, state) =>
            AppMessenger.showError(context, state.errorMessage!),
        builder: (context, state) {
          if (!state.hasCatalog) {
            return Scaffold(
              body: SafeArea(
                child: AppLoadState(
                  skeleton: const FridgeSkeleton(),
                  isLoading: state.status == FridgeStatus.loading,
                  message:
                      state.errorMessage ?? 'Chưa có danh sách nguyên liệu.',
                  onRetry: context.read<FridgeCubit>().loadFridge,
                ),
              ),
            );
          }
          return const ResponsiveLayout(
            mobile: FridgeMobileView(),
            tablet: FridgeTabletView(),
          );
        },
      ),
    );
  }
}
