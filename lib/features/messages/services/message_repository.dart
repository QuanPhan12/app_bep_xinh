import '../models/chat_recipe.dart';
import '../models/conversation.dart';
import '../../recipes/models/recipe_image.dart';

abstract interface class MessageRepository {
  Stream<List<Conversation>> watchInbox();
  Stream<Conversation> watchConversation(String id);
  Future<void> deleteConversation(String id);
  Future<List<MessageRecipient>> loadRecipients();
  Future<List<ChatRecipe>> loadRecipes();
  Future<String> startConversation(MessageRecipient recipient);
  Future<ChatMessage> send(
    String conversationId,
    String text, {
    required String requestId,
    RecipeImage? image,
    ChatRecipe? recipe,
  });
}
