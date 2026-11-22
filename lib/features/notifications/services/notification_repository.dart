import '../models/inbox_notification.dart';

abstract interface class NotificationRepository {
  Stream<List<InboxNotification>> watch();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}
