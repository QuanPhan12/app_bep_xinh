import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/widgets/app_inbox_components.dart';
import '../../../core/widgets/app_load_state.dart';
import '../cubits/notifications_cubit.dart';
import '../models/inbox_notification.dart';
import 'notification_tile.dart';

class NotificationsContent extends StatelessWidget {
  final ValueChanged<InboxNotification> onOpen;
  const NotificationsContent({super.key, required this.onOpen});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          final cubit = context.read<NotificationsCubit>();
          return AppInboxBody(
            onRefresh: cubit.load,
            children: [
              AppInboxFilters(
                unreadOnly: state.unreadOnly,
                unreadCount: state.unreadCount,
                onChanged: cubit.filterUnread,
              ),
              const SizedBox(height: 16),
              if (state.loading && state.items.isEmpty)
                const SizedBox(
                  height: 280,
                  child: AppLoadState(isLoading: true),
                )
              else if (state.error != null)
                AppLoadState(message: state.error, onRetry: cubit.load),
              if (!state.loading &&
                  state.error == null &&
                  state.visibleItems.isEmpty)
                AppInboxEmpty(
                  icon: PhosphorIconsRegular.bellSimple,
                  title: state.unreadOnly
                      ? 'Bạn đã đọc hết rồi'
                      : 'Góc bếp chưa có tin mới',
                  description: state.unreadOnly
                      ? 'Những cập nhật mới sẽ xuất hiện ở đây.'
                      : 'Khi công thức được duyệt hoặc cần chỉnh sửa, bạn sẽ nhận được thông báo tại đây.',
                ),
              for (final item in state.visibleItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NotificationTile(
                    item: item,
                    onOpen: state.updating ? null : () => onOpen(item),
                  ),
                ),
            ],
          );
        },
      );
}
