import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../widgets/home_action_scope.dart';
import '../widgets/home_app_bar.dart';

import '../widgets/home_skeleton.dart';

import 'package:app_bep_xinh/core/widgets/responsive_layout.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/home/home.dart';
import '../services/home_service.dart';
import 'views/home_mobile_view.dart';
import 'views/home_tablet_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeActionScope(
      openKitchen: () {
        context.push('/kitchen');
      },
      // Future của push chỉ hoàn tất khi màn con đóng. Callback điều hướng
      // kết thúc ngay để khóa tap không chặn thao tác trên màn vừa mở.
      openNotifications: () {
        context.push(PathRouter.notificationsScreen);
      },
      openMessages: () {
        context.push(PathRouter.messagesScreen);
      },
      child: BlocProvider(
        create: (context) =>
            HomeCubit(service: context.read<HomeService>())..loadHome(),
        child: BlocConsumer<HomeCubit, HomeState>(
          buildWhen: (previous, current) =>
              previous.hasContent != current.hasContent || !current.hasContent,
          listenWhen: (previous, current) =>
              current.hasContent &&
              current.errorMessage != null &&
              previous.errorMessage != current.errorMessage,
          listener: (context, state) =>
              AppMessenger.showError(context, state.errorMessage!),
          builder: (context, state) {
            if (!state.hasContent) {
              return Scaffold(
                body: CustomScrollView(
                  slivers: [
                    const HomeAppBar(),
                    SliverFillRemaining(
                      child: AppLoadState(
                        skeleton: const HomeSkeleton(),
                        isLoading: state.status == HomeStatus.loading,
                        message:
                            state.errorMessage ?? 'Chưa có nội dung trang chủ.',
                        onRetry: context.read<HomeCubit>().loadHome,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const ResponsiveLayout(
              mobile: HomeMobileView(),
              tablet: HomeTabletView(),
            );
          },
        ),
      ),
    );
  }
}
