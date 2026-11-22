import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/core/widgets/app_unread_indicator.dart';
import 'package:app_bep_xinh/features/home/cubits/home_unread/home_unread_cubit.dart';
import 'package:app_bep_xinh/features/home/widgets/home_action_scope.dart';
import 'package:app_bep_xinh/features/home/widgets/home_app_bar.dart';
import 'package:app_bep_xinh/features/home/widgets/home_unread_scope.dart';
import 'package:app_bep_xinh/features/messages/services/message_repository.dart';
import 'package:app_bep_xinh/features/notifications/models/inbox_notification.dart';
import 'package:app_bep_xinh/features/notifications/services/notification_repository.dart';

import '../../support/communication_fakes.dart';
import '../../support/test_text_styles.dart';

void main() {
  setUpAll(configureTestTextStyles);

  test('unread snapshots update independently, errors retain counts and close cancels', () async {
    final notifications = FakeNotificationRepository();
    final messages = FakeMessageRepository();
    final cubit = HomeUnreadCubit(
      notifications: notifications,
      messages: messages,
    )..start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.notifications, 1);
    expect(cubit.state.conversations, 1);
    notifications.changes.addError(StateError('offline'));
    messages.inboxChanges.addError(StateError('offline'));
    await Future<void>.delayed(Duration.zero);
    expect(
      cubit.state,
      const HomeUnreadState(notifications: 1, conversations: 1),
    );
    await notifications.markAllRead();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.notifications, 0);
    expect(cubit.state.conversations, 1);
    await cubit.close();
    expect(notifications.cancellations, 1);
    expect(messages.cancellations, 1);
    final last = cubit.state;
    notifications.publish(const []);
    messages.inboxChanges.add([]);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, last);
    await notifications.dispose();
    await messages.dispose();
  });

  testWidgets(
    'Home indicators reflect unread data and reset outside signed-in scope',
    (tester) async {
      final notifications = FakeNotificationRepository();
      final messages = FakeMessageRepository();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await notifications.dispose();
        await messages.dispose();
      });
      Widget host(bool enabled) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider<NotificationRepository>.value(
            value: notifications,
          ),
          RepositoryProvider<MessageRepository>.value(value: messages),
        ],
        child: HomeUnreadScope(
          enabled: enabled,
          child: MaterialApp(
            home: HomeActionScope(
              openNotifications: () {},
              openMessages: () {},
              child: const Scaffold(
                body: CustomScrollView(slivers: [HomeAppBar()]),
              ),
            ),
          ),
        ),
      );
      bool unread(String tooltip) => tester
          .widget<AppUnreadIndicator>(
            find.descendant(
              of: find.byTooltip(tooltip),
              matching: find.byType(AppUnreadIndicator),
            ),
          )
          .hasUnread;

      await tester.pumpWidget(host(true));
      await tester.pumpAndSettle();
      expect(unread('Thông báo'), isTrue);
      expect(unread('Nhắn tin'), isTrue);
      await notifications.markRead('n1');
      messages.thread = messages.thread.copyWith(unreadCount: 0);
      messages.inboxChanges.add([messages.thread]);
      await tester.pumpAndSettle();
      expect(unread('Thông báo'), isFalse);
      expect(unread('Nhắn tin'), isFalse);
      notifications.publish(const [
        InboxNotification(
          id: 'fresh',
          title: 'Tin mới',
          body: 'Nội dung',
          timeLabel: '10:00',
          kind: NotificationKind.recipe,
        ),
      ]);
      messages.thread = messages.thread.copyWith(unreadCount: 1);
      messages.inboxChanges.add([messages.thread]);
      await tester.pumpAndSettle();
      expect(unread('Thông báo'), isTrue);
      expect(unread('Nhắn tin'), isTrue);

      await tester.pumpWidget(host(false));
      await tester.pumpAndSettle();
      expect(unread('Thông báo'), isFalse);
      expect(unread('Nhắn tin'), isFalse);
      expect(notifications.cancellations, 1);
      expect(messages.cancellations, 1);
    },
  );
}
