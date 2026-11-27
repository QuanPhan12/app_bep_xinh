import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_user_store.dart';
import '../../ai_chat/models/ai_message.dart';

class NutritionLease {
  final int lease;
  final String? result;
  const NutritionLease(this.lease, [this.result]);
}

abstract interface class NutritionAiStore {
  Future<NutritionLease> reserve(String id, String digest, int limit);
  Future<void> finish(String id, int lease, String? result);
}

class FirestoreNutritionAiStore implements NutritionAiStore {
  final FirestoreUserStore store;
  const FirestoreNutritionAiStore(this.store);
  String _day(int millis) => DateTime.fromMillisecondsSinceEpoch(
    millis,
    isUtc: true,
  ).add(const Duration(hours: 7)).toIso8601String().substring(0, 10);
  DocumentReference<Map<String, dynamic>> _job(String id) =>
      store.firestore.doc('ai_nutrition_threads/${store.uid}/requests/$id');
  @override
  Future<NutritionLease> reserve(String id, String digest, int limit) async {
    store.checkSession();
    final now = DateTime.now().millisecondsSinceEpoch;
    final quota = store.firestore.doc(
      'ai_chat_threads/${store.uid}/days/${_day(now)}',
    );
    final result = await store.firestore.runTransaction((tx) async {
      final old = (await tx.get(_job(id))).data();
      final daily = (await tx.get(quota)).data() ?? {};
      store.checkSession();
      if (old != null && old['digest'] != digest) {
        throw const AiChatFailure('Nội dung lượt ước tính đã thay đổi.');
      }
      if (old?['status'] == 'done') {
        return NutritionLease(0, old!['resultJson'] as String);
      }
      if ((daily['activeUntil'] as num? ?? 0) > now) {
        throw const AiChatFailure('Vui lòng chờ lượt AI đang xử lý.');
      }
      if ((daily['count'] as num? ?? 0) >= limit) {
        throw const AiChatFailure(
          'Đã đạt giới hạn AI hôm nay. Chat và calo dùng chung hạn mức.',
        );
      }
      final attempts = (old?['attempts'] as num? ?? 0).toInt() + 1;
      tx.set(_job(id), {
        'digest': digest,
        'status': 'processing',
        'lease': now,
        'attempts': attempts,
        'resultJson': null,
      });
      tx.set(quota, {
        'count': (daily['count'] as num? ?? 0).toInt() + 1,
        'activeUntil': now + 60000,
      });
      tx.set(store.firestore.doc('ai_chat_events/${store.uid}_$id'), {
        'uid': store.uid,
        'status': 'processing',
        'attemptedAtMillis': now,
        'leaseUntil': now + 60000,
        'attempts': attempts,
        'expiresAt': Timestamp.fromMillisecondsSinceEpoch(now + 7 * 86400000),
      });
      return NutritionLease(now);
    });
    store.checkSession();
    return result;
  }

  @override
  Future<void> finish(String id, int lease, String? result) async {
    store.checkSession();
    final quota = store.firestore.doc(
      'ai_chat_threads/${store.uid}/days/${_day(lease)}',
    );
    await store.firestore.runTransaction((tx) async {
      final old = (await tx.get(_job(id))).data();
      final daily = (await tx.get(quota)).data();
      store.checkSession();
      if (old?['status'] != 'processing' || old?['lease'] != lease) {
        throw const AiChatFailure('Lượt ước tính đã hết hạn. Hãy thử lại.');
      }
      final status = result == null ? 'failed' : 'done';
      tx.update(_job(id), {'status': status, 'resultJson': result});
      tx.update(store.firestore.doc('ai_chat_events/${store.uid}_$id'), {
        'status': status,
      });
      // Không giải phóng khóa của một lượt mới đã bắt đầu sau khi lease này hết hạn.
      if (daily?['activeUntil'] == lease + 60000) {
        tx.update(quota, {'activeUntil': 0});
      }
    });
    store.checkSession();
  }
}
