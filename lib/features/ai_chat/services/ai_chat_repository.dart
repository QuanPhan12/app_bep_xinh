import '../models/ai_message.dart';
import '../../messages/models/chat_history_page.dart';

abstract interface class AiChatRepository {
  Future<ChatHistoryPage<AiMessage>> history();
  Future<List<AiMessage>> send(String message, String requestId);
}
