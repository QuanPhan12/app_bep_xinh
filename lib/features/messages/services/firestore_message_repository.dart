import '../models/chat_recipe.dart';

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../../../core/services/firestore_user_store.dart';
import '../../../core/services/json_reader.dart';
import '../../../core/utils/inbox_time_label.dart';
import '../../recipes/services/published_recipe_source.dart';
import '../../recipes/models/recipe_image.dart';
import '../models/conversation.dart';
import 'message_repository.dart';

class FirestoreMessageRepository implements MessageRepository {
  final FirestoreUserStore store;
  final PublishedRecipeSource published;
  FirestoreMessageRepository({required this.store, required this.published});
  CollectionReference<Map<String, dynamic>> get _threads =>
      store.firestore.collection('conversations');

  void _checkId(String id) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(id)) {
      throw const FormatException('Invalid conversation');
    }
    store.checkSession();
  }

  Conversation _thread(
    String id,
    Map<String, dynamic> data, {
    List<ChatMessage>? messages,
  }) {
    final members = JsonReader(data).strings('memberIds', allowEmpty: false);
    if (members.length != 2 || !members.contains(store.uid)) {
      throw StateError('Invalid membership');
    }
    final peer = members.firstWhere((uid) => uid != store.uid);
    final names = Map<String, dynamic>.from(data['memberNames'] as Map);
    final name = JsonReader(names).string(peer);
    final updatedAt = data['updatedAt'] as Timestamp?;
    final readAt = (data['readAt'] as Map?)?[store.uid] as Timestamp?;
    final lastText = JsonReader(data)
        .string('lastMessageText', allowEmpty: true);
    return Conversation(
      id: id,
      name: name,
      subtitle: 'Cùng chia sẻ chuyện vào bếp',
      unreadCount:
          data['lastSenderId'] != null &&
              data['lastSenderId'] != store.uid &&
              updatedAt != null &&
              (readAt == null || updatedAt.compareTo(readAt) > 0)
          ? 1
          : 0,
      messages:
          messages ??
          (lastText.isEmpty
              ? const []
              : [
                  ChatMessage(
                    id: data['lastMessageId'] as String,
                    text: lastText,
                    timeLabel: inboxTimeLabel(updatedAt?.toDate()),
                    fromMe: data['lastSenderId'] == store.uid,
                  ),
                ]),
    );
  }

  @override
  Stream<List<Conversation>> watchInbox() {
    store.checkSession();
    return _threads
        .where('memberIds', arrayContains: store.uid)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          store.checkSession();
          return [for (final doc in snapshot.docs) _thread(doc.id, doc.data())];
        });
  }

  @override
  Stream<Conversation> watchConversation(String id) async* {
    _checkId(id);
    final reference = _threads.doc(id);
    final snapshot = await reference.get();
    store.checkSession();
    if (!snapshot.exists) throw StateError('Conversation not found');
    final data = snapshot.data()!;
    _thread(id, data);
    yield* reference
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .asyncMap((snapshot) async {
          store.checkSession();
          final messages = [
            for (final doc in snapshot.docs.reversed)
              ChatMessage(
                id: doc.id,
                text: JsonReader(doc.data()).string('text', allowEmpty: true),
                recipe: doc.data()['recipe'] == null
                    ? null
                    : ChatRecipe.fromJson(
                        Map<String, dynamic>.from(doc.data()['recipe'] as Map),
                      ),
                image: doc.data()['image'] == null
                    ? null
                    : RecipeImage.fromJson(
                        Map<String, dynamic>.from(doc.data()['image'] as Map),
                      ),
                timeLabel: inboxTimeLabel(
                  (doc.data()['createdAt'] as Timestamp?)?.toDate(),
                ),
                fromMe: doc.data()['senderId'] == store.uid,
              ),
          ];
          // Chỉ xác nhận đã đọc sau snapshot đã commit; tránh pending timestamp
          // làm một tin đang gửi trông như đã được máy chủ xác nhận.
          if (!snapshot.metadata.hasPendingWrites) {
            await _markRead(id);
          }
          return _thread(id, data, messages: messages);
        });
  }

  Future<void> _markRead(String id) async {
    store.checkSession();
    await _threads.doc(id).update({
      FieldPath(['readAt', store.uid]): FieldValue.serverTimestamp(),
    });
    store.checkSession();
  }

  @override
  Future<List<ChatRecipe>> loadRecipes() async {
    store.checkSession();
    final entries = await published.fetchPublished();
    store.checkSession();
    return [
      for (final entry in entries)
        ChatRecipe.fromJson({
          'id': entry['id'],
          'title': entry['title'],
          'cover': entry['cover'],
        }),
    ];
  }

  @override
  Future<List<MessageRecipient>> loadRecipients() async {
    store.checkSession();
    final entries = await published.fetchPublished();
    store.checkSession();
    final people = <String, MessageRecipient>{};
    for (final entry in entries) {
      if (entry['author'] is! Map) continue;
      final author = JsonReader(
        Map<String, dynamic>.from(entry['author'] as Map),
      );
      final id = author.string('id');
      if (id != store.uid) {
        people.putIfAbsent(
          id,
          () => MessageRecipient(
            id: id,
            name: author.string('name'),
            recipeId: JsonReader(entry).string('id'),
          ),
        );
      }
    }
    return people.values.toList();
  }

  @override
  Future<String> startConversation(MessageRecipient recipient) async {
    store.checkSession();
    if (recipient.id == store.uid || recipient.id.contains('/')) {
      throw const FormatException('Invalid recipient');
    }
    final account = await store.ensureAccount();
    final members = [store.uid, recipient.id]..sort();
    final id = sha256.convert(utf8.encode(jsonEncode(members))).toString();
    final reference = _threads.doc(id);
    await store.firestore.runTransaction((transaction) async {
      final current = await transaction.get(reference);
      if (current.exists) return;
      transaction.set(reference, {
        'memberIds': members,
        'memberNames': {store.uid: account.name, recipient.id: recipient.name},
        'recipeId': recipient.recipeId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessageId': null,
        'lastMessageText': '',
        'lastSenderId': null,
        'readAt': {store.uid: FieldValue.serverTimestamp()},
      });
    });
    store.checkSession();
    return id;
  }

  @override
  Future<ChatMessage> send(
    String conversationId,
    String text, {
    required String requestId,
    RecipeImage? image,
    ChatRecipe? recipe,
  }) async {
    _checkId(conversationId);
    final normalized = text.trim();
    if ((normalized.isEmpty && image == null && recipe == null) ||
        (image != null && recipe != null) ||
        normalized.length > 2000 ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(requestId)) {
      throw const FormatException('Invalid message');
    }
    final imageData = image == null
        ? null
        : RecipeImage.fromJson(image.toJson());
    if (imageData != null &&
        (imageData.url == null ||
            imageData.publicId == null ||
            imageData.id.length > 128 ||
            imageData.name.length > 120 ||
            imageData.publicId!.length > 500)) {
      throw const FormatException('Invalid message image');
    }
    final recipeData = recipe == null
        ? null
        : ChatRecipe.fromJson(recipe.toJson());
    final preview = normalized.isNotEmpty
        ? normalized
        : recipeData != null
        ? '🍽 ${recipeData.title}'
        : '📷 Ảnh';
    final reference = _threads.doc(conversationId);
    final message = reference.collection('messages').doc(requestId);
    // Transaction giữ preview và tin nhắn cùng một lần commit, không cho
    // timestamp pending hoặc hai người gửi đồng thời ghi đè lịch sử.
    await store.firestore
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(reference);
          final existing = await transaction.get(message);
          if (!snapshot.exists) throw StateError('Conversation not found');
          _thread(conversationId, snapshot.data()!);
          // Mất phản hồi sau commit vẫn có thể thử lại cùng ID mà không gửi trùng.
          if (existing.exists) {
            final persistedImage = existing.data()!['image'] == null
                ? null
                : RecipeImage.fromJson(
                    Map<String, dynamic>.from(existing.data()!['image'] as Map),
                  );
            final persistedRecipe = existing.data()!['recipe'] == null
                ? null
                : ChatRecipe.fromJson(
                    Map<String, dynamic>.from(
                      existing.data()!['recipe'] as Map,
                    ),
                  );
            if (existing.data()!['senderId'] != store.uid ||
                existing.data()!['text'] != normalized ||
                persistedImage != imageData ||
                persistedRecipe != recipeData) {
              throw StateError('Message request conflict');
            }
            return;
          }
          if (recipeData != null) {
            final source = await transaction.get(
              store.firestore.collection('recipes').doc(recipeData.id),
            );
            final data = source.data();
            // Chặn gửi món vừa bị ẩn/xóa và snapshot giả mạo, kể cả picker đã tải trước đó.
            if (data?['status'] != 'approved' ||
                ChatRecipe.fromJson({
                      'id': source.id,
                      'title': (data?['content'] as Map?)?['title'],
                      'cover': (data?['content'] as Map?)?['cover'],
                    }) !=
                    recipeData) {
              throw StateError('Recipe is no longer available');
            }
          }
          transaction.set(message, {
            'senderId': store.uid,
            'text': normalized,
            'createdAt': FieldValue.serverTimestamp(),
            if (imageData != null) 'image': imageData.toJson(),
            if (recipeData != null) 'recipe': recipeData.toJson(),
          });
          transaction.update(reference, {
            'lastMessageId': message.id,
            'lastMessageText': preview,
            'lastSenderId': store.uid,
            'updatedAt': FieldValue.serverTimestamp(),
            FieldPath(['readAt', store.uid]): FieldValue.serverTimestamp(),
          });
        }, timeout: const Duration(seconds: 20))
        .timeout(const Duration(seconds: 25));
    store.checkSession();
    return ChatMessage(
      id: message.id,
      text: normalized,
      timeLabel: 'Vừa xong',
      fromMe: true,
      image: imageData,
      recipe: recipeData,
    );
  }
}
