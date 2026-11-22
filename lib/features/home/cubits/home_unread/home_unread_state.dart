import 'package:equatable/equatable.dart';

class HomeUnreadState extends Equatable {
  final int notifications;
  final int conversations;

  const HomeUnreadState({this.notifications = 0, this.conversations = 0});

  HomeUnreadState copyWith({int? notifications, int? conversations}) =>
      HomeUnreadState(
        notifications: notifications ?? this.notifications,
        conversations: conversations ?? this.conversations,
      );

  @override
  List<Object?> get props => [notifications, conversations];
}
