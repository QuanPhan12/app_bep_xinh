import '../models/ai_message.dart';

abstract interface class AiChatRepository {
  Future<List<AiMessage>> history();
  Future<List<AiMessage>> send(String message, String requestId);
}
