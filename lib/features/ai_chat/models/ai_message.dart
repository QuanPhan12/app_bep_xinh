import '../../messages/models/chat_recipe.dart';

class AiMessage {
  final String id, role, text;
  final List<ChatRecipe> recipes;
  const AiMessage({
    required this.id,
    required this.role,
    required this.text,
    this.recipes = const [],
  });
  bool get fromAi => role == 'assistant';
  factory AiMessage.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['text'] is! String ||
        (json['text'] as String).length > 6000 ||
        !['user', 'assistant'].contains(json['role']) ||
        json['recipes'] is! List ||
        (json['recipes'] as List).length > 4) {
      throw const FormatException('Invalid AI message');
    }
    return AiMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      text: json['text'] as String,
      recipes: List.unmodifiable(
        (json['recipes'] as List).map(
          (r) => ChatRecipe.fromJson(Map<String, dynamic>.from(r as Map)),
        ),
      ),
    );
  }
}

class AiChatFailure implements Exception {
  final String message;
  const AiChatFailure(this.message);
}
