import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/colors/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/widgets/widgets.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../cubits/profile/profile_cubit.dart';
import '../services/profile_service.dart';
import '../widgets/profile_content.dart';
import '../widgets/profile_app_bar.dart';
import '../widgets/profile_skeleton.dart';
import '../../kitchen/services/kitchen_services.dart';

class ProfileScreen extends StatelessWidget {
  final bool showSaved;
  const ProfileScreen({super.key, this.showSaved = false});

  @override
  Widget build(BuildContext context) {
    // Đăng ký phụ thuộc ở build; context tạo provider chỉ đọc dependency một lần,
    // không được lắng nghe InheritedWidget trong quá trình khởi tạo Cubit.
    final kitchen = KitchenScope.maybeOf(context);
    return BlocProvider(
      key: ValueKey(showSaved),
      create: (providerContext) =>
          ProfileCubit(
              service: providerContext.read<ProfileService>(),
              favorites: providerContext.read<RecipeFavoritesService>(),
              loadCookingLogCount: kitchen?.journal.count,
            )
            ..selectTab(showSaved ? ProfileTab.saved : ProfileTab.recipes)
            ..load(),
      child: const _ProfilePage(),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.background,
    body: SafeArea(
      top: false,
      bottom: false,
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (a, b) => a.noticeId != b.noticeId,
        listener: (context, state) {
          if (state.message != null) {
            AppMessenger.showError(context, state.message!);
          }
        },
        builder: (context, state) => state.data != null
            ? const ProfileContent()
            : CustomScrollView(
                slivers: [
                  ProfileAppBar(
                    onSettings: () => context.push(PathRouter.settingsScreen),
                  ),
                  SliverFillRemaining(
                    child: AppLoadState(
                      isLoading:
                          state.status == ProfileStatus.initial ||
                          state.status == ProfileStatus.loading,
                      message: state.message,
                      onRetry: context.read<ProfileCubit>().load,
                      skeleton: const ProfileSkeleton(),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
