import 'package:equatable/equatable.dart';

import '../models/inbox_notification.dart';

class NotificationsState extends Equatable {
  final List<InboxNotification> items;
  final bool loading;
  final bool updating;
  final bool unreadOnly;
  final String? error;

  const NotificationsState({
    this.items = const [],
    this.loading = true,
    this.updating = false,
    this.unreadOnly = false,
    this.error,
  });

  int get unreadCount => items.where((item) => !item.isRead).length;
  List<InboxNotification> get visibleItems =>
      items.where((item) => !unreadOnly || !item.isRead).toList();

  NotificationsState copyWith({
    List<InboxNotification>? items,
    bool? loading,
    bool? updating,
    bool? unreadOnly,
    String? error,
  }) => NotificationsState(
    items: items == null ? this.items : List.unmodifiable(items),
    loading: loading ?? this.loading,
    updating: updating ?? this.updating,
    unreadOnly: unreadOnly ?? this.unreadOnly,
    error: error,
  );

  @override
  List<Object?> get props => [items, loading, updating, unreadOnly, error];
}
