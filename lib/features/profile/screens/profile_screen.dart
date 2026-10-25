import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:app_bep_xinh/core/widgets/widgets.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../cubits/profile/profile_cubit.dart';
import '../services/profile_service.dart';
import '../widgets/profile_content.dart';
import '../widgets/profile_skeleton.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ProfileCubit(
      service: context.read<ProfileService>(),
      favorites: context.read<RecipeFavoritesService>(),
    )..load(),
    child: const _ProfilePage(),
  );
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppLayout.pageWidth(context)),
          child: BlocConsumer<ProfileCubit, ProfileState>(
            listenWhen: (a, b) => a.noticeId != b.noticeId,
            listener: (context, state) {
              if (state.message != null) {
                AppMessenger.showError(context, state.message!);
              }
            },
            builder: (context, state) => state.data != null
                ? const ProfileContent()
                : AppLoadState(
                    isLoading:
                        state.status == ProfileStatus.initial ||
                        state.status == ProfileStatus.loading,
                    message: state.message,
                    onRetry: context.read<ProfileCubit>().load,
                    skeleton: const ProfileSkeleton(),
                  ),
          ),
        ),
      ),
    ),
  );
}
