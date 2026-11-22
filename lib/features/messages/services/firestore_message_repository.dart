import '../models/chat_recipe.dart';

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../../../core/services/firestore_user_store.dart';
import '../../../core/services/json_reader.dart';
import '../../../core/utils/inbox_time_label.dart';
import '../../recipes/services/published_recipe_source.dart';
import '../../recipes/models/recipe_image.dart';
import '../models/conversation.dart';
import '../models/chat_history_page.dart';
import 'message_repository.dart';

class FirestoreMessageRepository implements MessageRepository {
  final FirestoreUserStore store;
  final PublishedRecipeSource published;
  FirestoreMessageRepository({required this.store, required this.published});
  CollectionReference<Map<String, dynamic>> get _threads =>
      store.firestore.collection('conversations');
  CollectionReference<Map<String, dynamic>> get _deletions =>
      store.account.collection('chat_deletions');

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
    LoadOlderMessages<ChatMessage>? loadOlder,
    Timestamp? deletedThrough,
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
      loadOlder: loadOlder,
      unreadCount:
          data['lastSenderId'] != null &&
              data['lastSenderId'] != store.uid &&
              updatedAt != null &&
              (deletedThrough == null ||
                  updatedAt.compareTo(deletedThrough) > 0) &&
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
    final inbox = _threads
        .where('memberIds', arrayContains: store.uid)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots();
    return Stream.multi((sink) {
      List<QueryDocumentSnapshot<Map<String, dynamic>>>? threads;
      Map<String, Timestamp>? deletedThrough;
      void publish() {
        final current = threads;
        final cutoffs = deletedThrough;
        if (current == null || cutoffs == null) return;
        try {
          store.checkSession();
          sink.add([
            for (final doc in current)
              if (_isVisibleInInbox(doc.data(), cutoffs[doc.id]))
                _thread(doc.id, doc.data()),
          ]);
        } catch (error, stack) {
          sink.addError(error, stack);
        }
      }

      final inboxSubscription = inbox.listen((snapshot) {
        threads = snapshot.docs;
        publish();
      }, onError: sink.addError);
      final deletionSubscription = _deletions
          .snapshots(includeMetadataChanges: true)
          .listen((snapshot) {
            // Đợi đồng bộ dấu xóa trước khi hiện hộp thư trên thiết bị mới.
            if (deletedThrough == null && snapshot.metadata.isFromCache) return;
            deletedThrough = {
              for (final doc in snapshot.docs)
                if (doc.data()['through'] case final Timestamp through)
                  doc.id: through,
            };
            publish();
          }, onError: sink.addError);
      sink.onCancel = () async {
        await Future.wait([
          inboxSubscription.cancel(),
          deletionSubscription.cancel(),
        ]);
      };
    });
  }

  bool _isVisibleInInbox(Map<String, dynamic> thread, Timestamp? through) {
    if (through == null) return true;
    final updatedAt = thread['updatedAt'];
    return updatedAt is Timestamp && updatedAt.compareTo(through) > 0;
  }

  @override
  Future<void> deleteConversation(String id) async {
    _checkId(id);
    final reference = _threads.doc(id);
    final deletion = _deletions.doc(id);
    await store.firestore.runTransaction((transaction) async {
      store.checkSession();
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (data == null || data['updatedAt'] is! Timestamp) {
        throw StateError('Conversation not found');
      }
      _thread(id, data);
      transaction.set(deletion, {'through': data['updatedAt']});
    });
    store.checkSession();
  }

  @override
  Stream<Conversation> watchConversation(String id) async* {
    _checkId(id);
    final reference = _threads.doc(id);
    const server = GetOptions(source: Source.server);
    final (snapshot, deletion) = await (
      reference.get(server),
      _deletions.doc(id).get(server),
    ).wait;
    store.checkSession();
    if (!snapshot.exists) throw StateError('Conversation not found');
    final data = snapshot.data()!;
    _thread(id, data);
    final through = deletion.data()?['through'] as Timestamp?;
    var messages = reference
        .collection('messages')
        .orderBy('createdAt', descending: true);
    if (through != null)
      messages = messages.where('createdAt', isGreaterThan: through);
    final committed = await _fetchMessages(messages);
    final page = _messagePage(messages, committed);
    if (committed.isNotEmpty) await _markRead(id);
    yield _thread(
      id,
      data,
      messages: page.messages,
      loadOlder: page.loadOlder,
      deletedThrough: through,
    );

    // The first page is fixed. The listener only reads messages newer than it,
    // so new arrivals cannot evict messages or leave gaps in older pages.
    final live = committed.isEmpty
        ? messages
        : messages.endBeforeDocument(committed.first);
    String? latestReadId = committed.firstOrNull?.id;
    await for (final update in live.snapshots(includeMetadataChanges: true)) {
      store.checkSession();
      final newer = update.docs
          .where(
            (doc) =>
                !doc.metadata.hasPendingWrites &&
                doc.data()['createdAt'] is Timestamp,
          )
          .toList();
      final latest = newer.firstOrNull;
      if (latest != null &&
          latest.id != latestReadId &&
          !update.metadata.isFromCache) {
        await _markRead(id);
        latestReadId = latest.id;
      }
      yield _thread(
        id,
        data,
        messages: [...page.messages, ...newer.reversed.map(_message)],
        loadOlder: page.loadOlder,
        deletedThrough: through,
      );
    }
  }

  ChatHistoryPage<ChatMessage> _messagePage(
    Query<Map<String, dynamic>> query,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) => ChatHistoryPage(
    List.unmodifiable(docs.reversed.map(_message)),
    loadOlder: docs.length < chatHistoryPageSize
        ? null
        : () async {
            store.checkSession();
            final older = await _fetchMessages(
              query.startAfterDocument(docs.last),
            );
            return _messagePage(query, older);
          },
  );

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchMessages(
    Query<Map<String, dynamic>> query,
  ) async {
    final page = query.limit(chatHistoryPageSize);
    const server = GetOptions(source: Source.server);
    var snapshot = await page.get(server);
    store.checkSession();
    // A local pending send can occupy a slot without a committed timestamp.
    // Use committed messages for the cursor so the first page has no gaps.
    if (snapshot.metadata.hasPendingWrites) {
      await store.firestore.waitForPendingWrites();
      store.checkSession();
      snapshot = await page.get(server);
      store.checkSession();
    }
    return snapshot.docs
        .where(
          (doc) =>
              !doc.metadata.hasPendingWrites &&
              doc.data()['createdAt'] is Timestamp,
        )
        .toList();
  }

  ChatMessage _message(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return ChatMessage(
      id: doc.id,
      text: JsonReader(data).string('text', allowEmpty: true),
      recipe: data['recipe'] == null
          ? null
          : ChatRecipe.fromJson(
              Map<String, dynamic>.from(data['recipe'] as Map),
            ),
      image: data['image'] == null
          ? null
          : RecipeImage.fromJson(
              Map<String, dynamic>.from(data['image'] as Map),
            ),
      timeLabel: inboxTimeLabel((data['createdAt'] as Timestamp?)?.toDate()),
      fromMe: data['senderId'] == store.uid,
    );
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
