import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_user_store.dart';
import '../../../core/services/json_reader.dart';
import '../../../core/utils/inbox_time_label.dart';
import '../models/inbox_notification.dart';
import 'notification_repository.dart';

/// Thông báo xuất phát từ quyết định duyệt thật trên recipes; client chỉ
/// sở hữu dấu đã đọc, không thể tự tạo một quyết định duyệt giả.
class FirestoreNotificationRepository implements NotificationRepository {
  final FirestoreUserStore store;
  List<InboxNotification> _latest = const [];
  FirestoreNotificationRepository(this.store);
  CollectionReference<Map<String, dynamic>> get _reads =>
      store.account.collection('notification_reads');

  @override
  Stream<List<InboxNotification>> watch() {
    late StreamController<List<InboxNotification>> controller;
    StreamSubscription? recipesSubscription;
    StreamSubscription? readsSubscription;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? recipes;
    Set<String>? reads;
    void publish() {
      if (recipes == null || reads == null || controller.isClosed) return;
      try {
        store.checkSession();
        final reviewed =
            recipes!
                .where(
                  (doc) =>
                      doc.data()['status'] == 'approved' ||
                      doc.data()['status'] == 'rejected',
                )
                .toList()
              ..sort(
                (a, b) =>
                    ((b.data()['reviewedAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0)
                        .compareTo(
                          (a.data()['reviewedAt'] as Timestamp?)
                                  ?.millisecondsSinceEpoch ??
                              0,
                        ),
              );
        _latest = [for (final doc in reviewed) _decode(doc, reads!)];
        controller.add(List.unmodifiable(_latest));
      } catch (error, stack) {
        controller.addError(error, stack);
      }
    }

    controller = StreamController<List<InboxNotification>>(
      onListen: () {
        try {
          store.checkSession();
          recipesSubscription = store.firestore
              .collection('recipes')
              .where('authorId', isEqualTo: store.uid)
              .orderBy('submittedAt', descending: true)
              .limit(100)
              .snapshots()
              .listen((snapshot) {
                recipes = snapshot.docs;
                publish();
              }, onError: controller.addError);
          readsSubscription = _reads.snapshots().listen((snapshot) {
            reads = snapshot.docs.map((doc) => doc.id).toSet();
            publish();
          }, onError: controller.addError);
        } catch (error, stack) {
          controller.addError(error, stack);
        }
      },
      onCancel: () async {
        await recipesSubscription?.cancel();
        await readsSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  InboxNotification _decode(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Set<String> reads,
  ) {
    final data = doc.data();
    final approved = data['status'] == 'approved';
    final title = JsonReader(Map<String, dynamic>.from(data['content'] as Map))
        .string('title');
    final id = '${doc.id}_${data['status']}';
    final reason = data['reviewReason'] as String?;
    return InboxNotification(
      id: id,
      title: approved
          ? 'Công thức của bạn đã được duyệt'
          : 'Công thức cần chỉnh sửa',
      body: approved
          ? '“$title” đã xuất hiện trong Bếp Xinh. Cảm ơn bạn đã chia sẻ một món ngon!'
          : '“$title” cần được cập nhật trước khi xuất bản.${reason == null ? '' : '\n\nGóp ý: $reason'}',
      timeLabel: inboxTimeLabel((data['reviewedAt'] as Timestamp?)?.toDate()),
      kind: NotificationKind.recipe,
      isRead: reads.contains(id),
      recipeId: approved ? doc.id : null,
    );
  }

  @override
  Future<void> markRead(String id) async {
    store.checkSession();
    if (!_latest.any((item) => item.id == id)) {
      throw StateError('Unknown notification');
    }
    await _reads.doc(id).set({'readAt': FieldValue.serverTimestamp()});
    store.checkSession();
  }

  @override
  Future<void> markAllRead() async {
    store.checkSession();
    final batch = store.firestore.batch();
    for (final item in _latest.where((item) => !item.isRead)) {
      batch.set(_reads.doc(item.id), {'readAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    store.checkSession();
  }
}
