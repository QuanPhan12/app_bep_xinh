import 'chat_recipe.dart';
import 'chat_history_page.dart';
import '../../recipes/models/recipe_image.dart';

class ChatMessage {
  final String id;
  final String text;
  final String timeLabel;
  final bool fromMe;
  final RecipeImage? image;
  final ChatRecipe? recipe;
  const ChatMessage({
    required this.id,
    required this.text,
    required this.timeLabel,
    this.fromMe = false,
    this.image,
    this.recipe,
  });
}

class Conversation {
  final String id;
  final String name;
  final String subtitle;
  final List<ChatMessage> messages;
  final int unreadCount;
  final LoadOlderMessages<ChatMessage>? loadOlder;
  const Conversation({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.messages,
    this.unreadCount = 0,
    this.loadOlder,
  });

  Conversation copyWith({List<ChatMessage>? messages, int? unreadCount}) =>
      Conversation(
        id: id,
        name: name,
        subtitle: subtitle,
        messages: List.unmodifiable(messages ?? this.messages),
        unreadCount: unreadCount ?? this.unreadCount,
        loadOlder: loadOlder,
      );
}

class MessageRecipient {
  final String id;
  final String name;
  final String recipeId;
  const MessageRecipient({
    required this.id,
    required this.name,
    required this.recipeId,
  });
}
