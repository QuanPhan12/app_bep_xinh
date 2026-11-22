import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/tap/tap_extension.dart';
import '../../../core/widgets/app_feature_theme.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_sliver_app_bar.dart';
import '../cubits/notifications_cubit.dart';
import '../services/notification_repository.dart';
import '../widgets/notification_details.dart';
import '../widgets/notifications_content.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        NotificationsCubit(context.read<NotificationRepository>())..load(),
    child: const AppFeatureTheme(child: _NotificationsPage()),
  );
}

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) => AppPageScaffold(
          appBar: AppSliverAppBar(
            title: 'Thông báo',
            onBackPressed: () => context.canPop()
                ? context.pop()
                : context.go(PathRouter.homeScreen),
            actions: [
              IconButton(
                tooltip: 'Đánh dấu tất cả đã đọc',
                icon: const Icon(PhosphorIconsRegular.checks),
                onPressed:
                    state.updating || state.loading || state.unreadCount == 0
                    ? null
                    : context.onAppTap(
                        () => context.read<NotificationsCubit>().markRead(null),
                        actionName: 'notifications_read_all',
                      ),
              ),
            ],
          ),
          body: NotificationsContent(
            onOpen: (item) {
              context.read<NotificationsCubit>().markRead(item.id);
              showNotificationDetails(
                context,
                item: item,
                onViewRecipe: () {
                  context.push(
                    item.recipeId == null
                        ? PathRouter.recipeSubmissionsScreen
                        : PathRouter.recipeDetail(item.recipeId!),
                  );
                },
              );
            },
          ),
        ),
      );
}
