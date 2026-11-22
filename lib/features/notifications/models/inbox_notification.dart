enum NotificationKind { recipe, kitchen, community }

class InboxNotification {
  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final NotificationKind kind;
  final bool isRead;
  final String? recipeId;

  const InboxNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.kind,
    this.isRead = false,
    this.recipeId,
  });

  InboxNotification read() => InboxNotification(
    id: id,
    title: title,
    body: body,
    timeLabel: timeLabel,
    kind: kind,
    isRead: true,
    recipeId: recipeId,
  );
}
