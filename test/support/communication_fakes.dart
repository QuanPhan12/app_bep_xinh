import 'package:app_bep_xinh/features/messages/models/chat_recipe.dart';

import 'dart:async';
import 'dart:io';

import 'package:app_bep_xinh/features/messages/services/chat_image_service.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_image.dart';

import 'package:app_bep_xinh/features/notifications/models/inbox_notification.dart';
import 'package:app_bep_xinh/features/notifications/services/notification_repository.dart';
import 'package:app_bep_xinh/features/messages/models/conversation.dart';
import 'package:app_bep_xinh/features/messages/services/message_repository.dart';

class FakeNotificationRepository implements NotificationRepository {
  List<InboxNotification> items = const [
    InboxNotification(
      id: 'n1',
      title: 'Công thức đã được duyệt',
      body: 'Món ngon của bạn đã được chia sẻ.',
      timeLabel: '09:30',
      kind: NotificationKind.recipe,
      recipeId: 'bo_ne_tieu_den',
    ),
  ];
  final changes = StreamController<List<InboxNotification>>.broadcast();
  Future<void> Function()? onMark;
  int cancellations = 0;
  @override
  Stream<List<InboxNotification>> watch() => Stream.multi((sink) {
    sink.add(items);
    final subscription = changes.stream.listen(
      sink.add,
      onError: sink.addError,
    );
    sink.onCancel = () {
      cancellations++;
      return subscription.cancel();
    };
  });
  void publish(List<InboxNotification> values) {
    items = values;
    changes.add(items);
  }

  @override
  Future<void> markRead(String id) async {
    await onMark?.call();
    publish([
      for (final item in items)
        if (item.id == id) item.read() else item,
    ]);
  }

  @override
  Future<void> markAllRead() async {
    final ids = items.map((item) => item.id).toSet();
    await onMark?.call();
    publish([
      for (final item in items)
        if (ids.contains(item.id)) item.read() else item,
    ]);
  }

  Future<void> dispose() => changes.close();
}

class FakeMessageRepository implements MessageRepository {
  static final conversationId = 'a' * 64;
  Conversation thread = Conversation(
    id: conversationId,
    name: 'Mai',
    subtitle: 'Chuyện vào bếp',
    unreadCount: 1,
    messages: const [
      ChatMessage(
        id: 'one',
        text: 'Cùng nấu một món ngon nhé!',
        timeLabel: '09:30',
      ),
    ],
  );
  final inboxChanges = StreamController<List<Conversation>>.broadcast();
  final conversationChanges = StreamController<Conversation>.broadcast();
  Future<void> Function()? onSend;
  Future<void> Function()? onStart;
  final requestIds = <String>[];
  int cancellations = 0;
  @override
  Stream<List<Conversation>> watchInbox() => Stream.multi((sink) {
    sink.add([thread]);
    final subscription = inboxChanges.stream.listen(
      sink.add,
      onError: sink.addError,
    );
    sink.onCancel = () {
      cancellations++;
      return subscription.cancel();
    };
  });
  @override
  Stream<Conversation> watchConversation(String id) => Stream.multi((sink) {
    if (id != thread.id) {
      sink.addError(StateError('not found'));
      sink.close();
      return;
    }
    thread = thread.copyWith(unreadCount: 0);
    inboxChanges.add([thread]);
    sink.add(thread);
    final subscription = conversationChanges.stream.listen(
      sink.add,
      onError: sink.addError,
    );
    sink.onCancel = () {
      cancellations++;
      return subscription.cancel();
    };
  });
  @override
  Future<List<MessageRecipient>> loadRecipients() async => [
    const MessageRecipient(id: 'mai', name: 'Mai', recipeId: 'recipe'),
  ];
  List<ChatRecipe> recipeOptions = const [
    ChatRecipe(
      id: 'r_chat_recipe',
      title: 'Trứng chiên hành',
      cover: RecipeImage.remote(
        id: 'food',
        name: 'food.png',
        url: 'https://res.cloudinary.com/ddqouziau/image/upload/v1/food.png',
        publicId: 'food',
      ),
    ),
  ];
  Future<List<ChatRecipe>> Function()? onRecipes;
  @override
  Future<List<ChatRecipe>> loadRecipes() =>
      onRecipes?.call() ?? Future.value(recipeOptions);

  @override
  Future<String> startConversation(MessageRecipient recipient) async {
    await onStart?.call();
    return thread.id;
  }

  @override
  Future<ChatMessage> send(
    String conversationId,
    String text, {
    required String requestId,
    RecipeImage? image,
    ChatRecipe? recipe,
  }) async {
    requestIds.add(requestId);
    await onSend?.call();
    final existing = thread.messages
        .where((item) => item.id == requestId)
        .firstOrNull;
    if (existing != null) return existing;
    final message = ChatMessage(
      id: requestId,
      text: text,
      timeLabel: 'Vừa xong',
      fromMe: true,
      image: image,
      recipe: recipe,
    );
    thread = thread.copyWith(messages: [...thread.messages, message]);
    conversationChanges.add(thread);
    inboxChanges.add([thread]);
    return message;
  }

  Future<void> dispose() async {
    await inboxChanges.close();
    await conversationChanges.close();
  }
}

class FakeChatImageService implements ChatImageService {
  RecipeImage? selection = RecipeImage.memory(
    id: 'picked',
    name: 'Ảnh trò chuyện',
    bytes: File('assets/images/logo.png').readAsBytesSync(),
  );
  int uploads = 0;
  Future<void> Function()? onUpload;
  Future<RecipeImage?> Function()? onPick;
  static const remote = RecipeImage.remote(
    id: 'picked',
    name: 'Ảnh trò chuyện',
    url: 'https://res.cloudinary.com/ddqouziau/image/upload/v1/chat-test.png',
    publicId: 'chat-test',
  );
  @override
  Future<RecipeImage?> pick() => onPick?.call() ?? Future.value(selection);
  @override
  Future<RecipeImage> upload(RecipeImage image) async {
    uploads++;
    await onUpload?.call();
    return remote;
  }
}
