import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ai_message.dart';
import 'direct_ai_store.dart';

class FirestoreDirectAiStore implements DirectAiStore {
  final FirebaseFirestore db;
  FirestoreDirectAiStore(this.db);
  DocumentReference<Map<String, dynamic>> _request(String uid, String id) =>
      db.doc('ai_chat_threads/$uid/requests/$id');
  CollectionReference<Map<String, dynamic>> _messages(String uid) =>
      db.collection('ai_chat_threads/$uid/messages');
  @override
  Future<Map<String, dynamic>> config() async =>
      (await db
              .doc('ai_settings/runtime')
              .get(const GetOptions(source: Source.server)))
          .data() ??
      {};
  @override
  Future<List<AiMessage>> history(String uid) async {
    final rows = await _messages(uid)
        .orderBy('createdAtMillis', descending: true)
        .limit(40)
        .get();
    return rows.docs.reversed
        .map((d) => AiMessage.fromJson({'id': d.id, ...d.data()}))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> recipes() async =>
      (await db
              .collection('recipes')
              .where('status', isEqualTo: 'approved')
              .orderBy('submittedAt', descending: true)
              .limit(100)
              .get())
          .docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
  @override
  Future<bool> isApproved(String id) async =>
      (await db.doc('recipes/$id').get()).data()?['status'] == 'approved';
  @override
  Future<AiReservation> reserve(
    String uid,
    String id,
    String message,
    int limit,
  ) async {
    final time = DateTime.now().millisecondsSinceEpoch;
    final day = DateTime.fromMillisecondsSinceEpoch(
      time,
      isUtc: true,
    ).add(const Duration(hours: 7)).toIso8601String().substring(0, 10);
    final ref = _request(uid, id),
        quotaRef = db.doc('ai_chat_threads/$uid/days/$day');
    return db.runTransaction((tx) async {
      final previous = (await tx.get(ref)).data();
      final quota = (await tx.get(quotaRef)).data() ?? {};
      if (previous != null && previous['text'] != message) {
        throw const AiChatFailure('Nội dung của lượt gửi đã thay đổi.');
      }
      if (previous?['status'] == 'done') {
        final user = await tx.get(_messages(uid).doc('${id}_u'));
        final ai = await tx.get(_messages(uid).doc('${id}_a'));
        return AiReservation(0, [
          AiMessage.fromJson({'id': user.id, ...user.data()!}),
          AiMessage.fromJson({'id': ai.id, ...ai.data()!}),
        ]);
      }
      if ((quota['activeUntil'] as num? ?? 0) > time) {
        throw const AiChatFailure('Vui lòng chờ lượt hỏi đang xử lý.');
      }
      if ((quota['count'] as num? ?? 0) >= limit) {
        throw const AiChatFailure('Đã đạt giới hạn hỏi AI hôm nay.');
      }
      final attempts = (previous?['attempts'] as int? ?? 0) + 1;
      tx.set(ref, {
        'text': message,
        'status': 'processing',
        'lease': time,
        'attempts': attempts,
      });
      tx.set(quotaRef, {
        'count': (quota['count'] as int? ?? 0) + 1,
        'activeUntil': time + 60000,
      });
      tx.set(db.doc('ai_chat_events/${uid}_$id'), {
        'uid': uid,
        'status': 'processing',
        'attemptedAtMillis': time,
        'leaseUntil': time + 60000,
        'attempts': attempts,
        'expiresAt': Timestamp.fromMillisecondsSinceEpoch(time + 7 * 86400000),
      });
      return AiReservation(time);
    });
  }

  @override
  Future<void> complete(
    String uid,
    String id,
    int lease,
    List<AiMessage> pair,
  ) => _finish(uid, id, lease, pair);
  @override
  Future<void> fail(String uid, String id, int lease) =>
      _finish(uid, id, lease, null);
  Future<void> _finish(
    String uid,
    String id,
    int lease,
    List<AiMessage>? pair,
  ) async {
    final ref = _request(uid, id), status = pair == null ? 'failed' : 'done';
    await db.runTransaction((tx) async {
      final old = (await tx.get(ref)).data();
      if (old?['lease'] != lease || old?['status'] != 'processing') {
        throw const AiChatFailure('Lượt hỏi đã hết hạn. Vui lòng thử lại.');
      }
      final event = db.doc('ai_chat_events/${uid}_$id');
      final time = DateTime.now().millisecondsSinceEpoch;
      final day = DateTime.fromMillisecondsSinceEpoch(
        lease,
        isUtc: true,
      ).add(const Duration(hours: 7)).toIso8601String().substring(0, 10);
      tx.update(ref, {'status': status});
      tx.update(event, {'status': status});
      tx.update(db.doc('ai_chat_threads/$uid/days/$day'), {'activeUntil': 0});
      if (pair != null) {
        for (var i = 0; i < pair.length; i++) {
          final message = pair[i];
          tx.set(_messages(uid).doc(message.id), {
            'role': message.role,
            'text': message.text,
            'recipes': message.recipes.map((r) => r.toJson()).toList(),
            'createdAtMillis': time + i,
          });
        }
      }
    });
  }
}
