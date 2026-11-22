import 'package:app_bep_xinh/core/widgets/app_sliver_app_bar.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:app_bep_xinh/core/widgets/app_page_scaffold.dart';
import 'package:app_bep_xinh/core/widgets/app_load_state.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubits/public_profile/public_profile_cubit.dart';
import '../services/public_profile_service.dart';
import '../widgets/profile_skeleton.dart';
import '../widgets/public_profile_content.dart';

class PublicProfileScreen extends StatelessWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});
  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(userId),
    create: (context) => PublicProfileCubit(
      userId: userId,
      service: context.read<PublicProfileService>(),
      favorites: context.read<RecipeFavoritesService>(),
    )..load(),
    child: const _PublicProfilePage(),
  );
}

class _PublicProfilePage extends StatelessWidget {
  const _PublicProfilePage();
  @override
  Widget build(BuildContext context) => AppPageScaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppSliverAppBar(
      title: 'Hồ sơ',
      onBackPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(PathRouter.homeScreen);
        }
      },
    ),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppLayout.pageWidth(context)),
          child: BlocConsumer<PublicProfileCubit, PublicProfileState>(
            listenWhen: (a, b) => a.noticeId != b.noticeId,
            listener: (context, state) {
              if (state.message != null) {
                AppMessenger.showError(context, state.message!);
              }
            },
            builder: (context, state) => state.data != null
                ? const PublicProfileContent()
                : AppLoadState(
                    isLoading:
                        state.status == PublicProfileStatus.initial ||
                        state.status == PublicProfileStatus.loading,
                    message: state.message,
                    onRetry: state.status == PublicProfileStatus.notFound
                        ? null
                        : context.read<PublicProfileCubit>().load,
                    skeleton: const ProfileSkeleton(),
                  ),
          ),
        ),
      ),
    ),
  );
}
