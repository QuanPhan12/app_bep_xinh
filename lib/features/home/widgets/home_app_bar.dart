import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/tap/tap_extension.dart';
import '../../../core/widgets/app_sliver_app_bar.dart';
import '../../../core/widgets/app_unread_indicator.dart';
import 'home_action_scope.dart';
import 'home_unread_scope.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});
  @override
  Widget build(BuildContext context) {
    final actions = HomeActionScope.of(context);
    final unread = HomeUnreadScope.of(context);
    return AppSliverAppBar.tab(
      title: 'Bếp Xinh',
      titleWidget: Text(
        'Bếp Xinh',
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -.4),
      ),
      actions: [
        IconButton(
          tooltip: 'Thông báo',
          icon: AppUnreadIndicator(
            hasUnread: unread.notifications > 0,
            unreadLabel: 'Có thông báo chưa đọc',
            child: const Icon(PhosphorIconsRegular.bell, size: 23),
          ),
          onPressed: context.onAppTap(
            actions.openNotifications,
            actionName: 'home_notifications',
            requiresAuth: true,
          ),
        ),
        IconButton(
          tooltip: 'Nhắn tin',
          icon: AppUnreadIndicator(
            hasUnread: unread.conversations > 0,
            unreadLabel: 'Có tin nhắn chưa đọc',
            child: const Icon(PhosphorIconsRegular.chatCircleDots, size: 23),
          ),
          onPressed: context.onAppTap(
            actions.openMessages,
            actionName: 'home_messages',
            requiresAuth: true,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
