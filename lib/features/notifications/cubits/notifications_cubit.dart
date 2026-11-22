import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/inbox_notification.dart';
import '../services/notification_repository.dart';
import 'notifications_state.dart';
export 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationRepository repository;
  StreamSubscription<List<InboxNotification>>? _subscription;
  Timer? _initialTimeout;
  int _revision = 0;
  NotificationsCubit(this.repository) : super(const NotificationsState());

  Future<void> load() async {
    if (isClosed || state.updating) return;
    final revision = ++_revision;
    _initialTimeout?.cancel();
    await _subscription?.cancel();
    if (isClosed || revision != _revision) return;
    emit(state.copyWith(loading: true));
    void fail() {
      _initialTimeout?.cancel();
      if (!isClosed && revision == _revision) {
        emit(
          state.copyWith(
            loading: false,
            error: 'Chưa tải được thông báo. Bạn thử lại nhé.',
          ),
        );
      }
    }

    _initialTimeout = Timer(const Duration(seconds: 20), fail);
    try {
      _subscription = repository.watch().listen((items) {
        _initialTimeout?.cancel();
        if (!isClosed && revision == _revision) {
          emit(state.copyWith(items: items, loading: false));
        }
      }, onError: (Object _) => fail());
    } catch (_) {
      fail();
    }
  }

  void filterUnread(bool value) {
    if (!isClosed) emit(state.copyWith(unreadOnly: value));
  }

  Future<void> markRead(String? id) async {
    if (isClosed || state.updating || state.loading) return;
    final markedIds = state.items
        .where((item) => id == null || item.id == id)
        .map((item) => item.id)
        .toSet();
    emit(state.copyWith(updating: true));
    try {
      if (id == null) {
        await repository.markAllRead().timeout(const Duration(seconds: 20));
      } else {
        await repository.markRead(id).timeout(const Duration(seconds: 20));
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            updating: false,
            items: [
              for (final item in state.items)
                if (markedIds.contains(item.id)) item.read() else item,
            ],
          ),
        );
      }
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            updating: false,
            error: 'Chưa đánh dấu được thông báo. Vui lòng thử lại.',
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    _revision++;
    _initialTimeout?.cancel();
    final subscription = _subscription;
    await super.close();
    await subscription?.cancel();
  }
}
