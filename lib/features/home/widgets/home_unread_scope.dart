import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../messages/services/message_repository.dart';
import '../../notifications/services/notification_repository.dart';
import '../cubits/home_unread/home_unread_cubit.dart';

/// Đặt dưới repository theo UID, trên router để badge cập nhật cả khi đọc ở màn con.
class HomeUnreadScope extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const HomeUnreadScope({
    super.key,
    required this.enabled,
    required this.child,
  });

  /// AppBar vẫn dùng độc lập được; ngoài phiên đăng nhập không có badge.
  static HomeUnreadState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HomeUnreadData>()?.state ??
      const HomeUnreadState();

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return _HomeUnreadData(state: const HomeUnreadState(), child: child);
    }
    return BlocProvider(
      create: (context) => HomeUnreadCubit(
        notifications: context.read<NotificationRepository>(),
        messages: context.read<MessageRepository>(),
      )..start(),
      child: BlocBuilder<HomeUnreadCubit, HomeUnreadState>(
        builder: (context, state) =>
            _HomeUnreadData(state: state, child: child),
      ),
    );
  }
}

class _HomeUnreadData extends InheritedWidget {
  final HomeUnreadState state;
  const _HomeUnreadData({required this.state, required super.child});

  @override
  bool updateShouldNotify(_HomeUnreadData oldWidget) =>
      state != oldWidget.state;
}
