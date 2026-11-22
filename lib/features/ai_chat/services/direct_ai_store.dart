import '../models/ai_message.dart';

class AiReservation {
  final int lease;
  final List<AiMessage>? cached;
  const AiReservation(this.lease, [this.cached]);
}

abstract interface class DirectAiStore {
  Future<Map<String, dynamic>> config();
  Future<List<AiMessage>> history(String uid);
  Future<List<Map<String, dynamic>>> recipes();
  Future<bool> isApproved(String id);
  Future<AiReservation> reserve(
    String uid,
    String id,
    String message,
    int limit,
  );
  Future<void> complete(String uid, String id, int lease, List<AiMessage> pair);
  Future<void> fail(String uid, String id, int lease);
}
