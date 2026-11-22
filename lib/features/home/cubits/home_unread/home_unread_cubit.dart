import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../messages/models/conversation.dart';
import '../../../messages/services/message_repository.dart';
import '../../../notifications/models/inbox_notification.dart';
import '../../../notifications/services/notification_repository.dart';
import 'home_unread_state.dart';

export 'home_unread_state.dart';

/// Theo dõi trong phạm vi phiên đăng nhập, kể cả khi Home đang bị màn con che.
class HomeUnreadCubit extends Cubit<HomeUnreadState> {
  final NotificationRepository notifications;
  final MessageRepository messages;
  StreamSubscription<List<InboxNotification>>? _notificationsSubscription;
  StreamSubscription<List<Conversation>>? _messagesSubscription;
  bool _started = false;

  HomeUnreadCubit({required this.notifications, required this.messages})
    : super(const HomeUnreadState());

  void start() {
    if (isClosed || _started) return;
    _started = true;
    // Lỗi mạng không có nghĩa là đã đọc hết: giữ dấu hiệu gần nhất trong lúc
    // SDK tự nối lại, không dùng badge để phát thông báo lỗi trên toàn ứng dụng.
    try {
      _notificationsSubscription = notifications.watch().listen((items) {
        if (!isClosed) {
          emit(
            state.copyWith(
              notifications: items.where((item) => !item.isRead).length,
            ),
          );
        }
      }, onError: (Object _) {});
    } catch (_) {}
    try {
      _messagesSubscription = messages.watchInbox().listen((items) {
        if (!isClosed) {
          emit(
            state.copyWith(
              conversations: items.where((item) => item.unreadCount > 0).length,
            ),
          );
        }
      }, onError: (Object _) {});
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    await super.close();
    await Future.wait([
      if (_notificationsSubscription != null)
        _notificationsSubscription!.cancel(),
      if (_messagesSubscription != null) _messagesSubscription!.cancel(),
    ]);
  }
}
