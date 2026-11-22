import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_bep_xinh/core/services/firestore_user_store.dart';
import 'package:app_bep_xinh/features/recipes/services/published_recipe_source.dart';
import 'package:app_bep_xinh/features/notifications/services/firestore_notification_repository.dart';
import 'package:app_bep_xinh/features/messages/services/firestore_message_repository.dart';
import 'package:app_bep_xinh/features/recipes/models/recipe_image.dart';

@JS('firebaseSmokeResult')
external JSString? get smokeResult;
@JS('firebaseSmokeResult')
external set smokeResult(JSString? value);
const options = FirebaseOptions(
  apiKey: 'demo-key',
  appId: '1:123456789:web:abcdef',
  messagingSenderId: '123456789',
  projectId: 'demo-bepxinh',
);
int checks = 0;
void check(bool condition, String message) {
  if (!condition) throw StateError(message);
  checks++;
}

Future<T> first<T>(Stream<T> stream, bool Function(T) predicate) =>
    stream.firstWhere(predicate).timeout(const Duration(seconds: 20));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  smokeResult = 'running'.toJS;
  try {
    final aliceApp = await Firebase.initializeApp(options: options);
    final bobApp = await Firebase.initializeApp(
      name: 'communication-peer',
      options: options,
    );
    Future<(FirebaseAuth, FirebaseFirestore)> setup(FirebaseApp app) async {
      final auth = FirebaseAuth.instanceFor(app: app);
      final db = FirebaseFirestore.instanceFor(app: app);
      await auth.useAuthEmulator('127.0.0.1', 9099);
      db.settings = const Settings(persistenceEnabled: false);
      db.useFirestoreEmulator('127.0.0.1', 8080);
      return (auth, db);
    }

    final (aliceAuth, aliceDb) = await setup(aliceApp);
    final (bobAuth, bobDb) = await setup(bobApp);
    final suffix = DateTime.now().microsecondsSinceEpoch;
    final aliceEmail = 'communication-alice-$suffix@example.test';
    await aliceAuth.createUserWithEmailAndPassword(
      email: aliceEmail,
      password: 'EmulatorOnly123!',
    );
    await aliceAuth.currentUser!.updateDisplayName('Alice');
    await bobAuth.createUserWithEmailAndPassword(
      email: 'communication-bob-$suffix@example.test',
      password: 'EmulatorOnly123!',
    );
    await bobAuth.currentUser!.updateDisplayName('Bob');
    final aliceStore = FirestoreUserStore(
      firestore: aliceDb,
      auth: aliceAuth,
      uid: aliceAuth.currentUser!.uid,
    );
    final bobStore = FirestoreUserStore(
      firestore: bobDb,
      auth: bobAuth,
      uid: bobAuth.currentUser!.uid,
    );
    await aliceStore.ensureAccount();
    await bobStore.ensureAccount();
    // Chỉ harness emulator mới tạo bài đã duyệt; SDK client không được nâng quyền.
    smokeResult =
        'COMMUNICATION_SEED:${jsonEncode([aliceStore.uid, bobStore.uid])}'.toJS;
    for (var i = 0; smokeResult?.toDart != 'COMMUNICATION_SEEDED'; i++) {
      if (i > 30) throw StateError('Seed handshake timed out');
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    final alice = FirestoreMessageRepository(
      store: aliceStore,
      published: PublishedRecipeSource(aliceDb),
    );
    final bob = FirestoreMessageRepository(
      store: bobStore,
      published: PublishedRecipeSource(bobDb),
    );
    final recipients = await alice.loadRecipients();
    check(
      recipients.length == 1 && recipients.single.id == bobStore.uid,
      'published author discovery without private user listing',
    );
    final id = await alice.startConversation(recipients.single);
    check(
      await alice.startConversation(recipients.single) == id,
      'one conversation per pair',
    );
    final initial = await alice
        .watchConversation(id)
        .first
        .timeout(const Duration(seconds: 20));
    check(
      initial.name == 'Bob' && initial.messages.isEmpty,
      'empty conversation uses real peer name',
    );
    final unread = first(
      bob.watchInbox(),
      (items) => items.any((item) => item.id == id && item.unreadCount > 0),
    );
    const requestId = '11111111111111111111111111111111';
    await alice.send(id, 'Xin chào\nCùng vào bếp nhé!', requestId: requestId);
    check(
      (await unread).single.messages.single.text.contains('Xin chào'),
      'recipient inbox updates realtime',
    );
    final incoming = await first(
      bob.watchConversation(id),
      (thread) => thread.messages.any((m) => m.id == requestId),
    );
    check(
      !incoming.messages.single.fromMe,
      'real recipient sees sender message',
    );
    await alice.send(id, 'Xin chào\nCùng vào bếp nhé!', requestId: requestId);
    final persisted = await aliceDb
        .collection('conversations')
        .doc(id)
        .collection('messages')
        .get(const GetOptions(source: Source.server));
    check(persisted.docs.length == 1, 'retry same request is idempotent');
    check(
      (await first(
            bob.watchInbox(),
            (items) => items.single.unreadCount == 0,
          )).single.id ==
          id,
      'opening marks read',
    );
    final reply = first(
      alice.watchConversation(id),
      (thread) => thread.messages.length == 2,
    );
    await bob.send(
      id,
      'Cảm ơn bạn!',
      requestId: '22222222222222222222222222222222',
    );
    check(
      (await reply).messages.last.text == 'Cảm ơn bạn!',
      'two-account reply realtime',
    );
    const image = RecipeImage.remote(
      id: 'sdk-photo',
      name: 'Ảnh trò chuyện',
      url: 'https://res.cloudinary.com/ddqouziau/image/upload/v1/sdk-chat.png',
      publicId: 'sdk-chat',
    );
    final photoReceived = first(
      bob.watchConversation(id),
      (thread) => thread.messages.any((message) => message.image != null),
    );
    await alice.send(
      id,
      '',
      requestId: '33333333333333333333333333333333',
      image: image,
    );
    final photo = (await photoReceived).messages.last;
    check(
      photo.text.isEmpty && photo.image == image && !photo.fromMe,
      'image-only message received realtime',
    );
    await alice.send(
      id,
      '',
      requestId: '33333333333333333333333333333333',
      image: image,
    );
    final imageDocuments = await aliceDb
        .collection('conversations')
        .doc(id)
        .collection('messages')
        .get(const GetOptions(source: Source.server));
    check(
      imageDocuments.docs.length == 3,
      'image retry idempotent across Firestore map key ordering',
    );
    final captionReceived = first(
      alice.watchConversation(id),
      (thread) => thread.messages.length == 4,
    );
    await bob.send(
      id,
      'Ảnh có chú thích',
      requestId: '44444444444444444444444444444444',
      image: image,
    );
    check(
      (await captionReceived).messages.last.image == image,
      'image plus caption received realtime',
    );
    final notifications = FirestoreNotificationRepository(aliceStore);
    final notices = await notifications.watch().first.timeout(
      const Duration(seconds: 20),
    );
    check(
      notices.length == 1 &&
          notices.single.recipeId == 'communication_alice_recipe',
      'real moderation notification',
    );
    final readNotice = first(
      notifications.watch(),
      (items) => items.single.isRead,
    );
    await notifications.markRead(notices.single.id);
    check(
      (await readNotice).single.isRead,
      'read receipt persists and updates realtime',
    );
    await aliceAuth.signOut();
    var rejected = false;
    try {
      alice.watchInbox();
    } on StateError {
      rejected = true;
    }
    check(rejected, 'stale session rejected');
    await aliceAuth.signInWithEmailAndPassword(
      email: aliceEmail,
      password: 'EmulatorOnly123!',
    );
    check(
      (await first(
            alice.watchInbox(),
            (items) =>
                items.isNotEmpty &&
                items.single.messages.isNotEmpty &&
                items.single.messages.single.text == 'Ảnh có chú thích',
          )).single.messages.single.text ==
          'Ảnh có chú thích',
      'messages survive sign-out/sign-in',
    );
    await alice.deleteConversation(id);
    check(
      (await alice.watchInbox().first.timeout(const Duration(seconds: 20)))
          .isEmpty,
      'deleted conversation is removed from the owner inbox',
    );
    final cleared = await alice
        .watchConversation(id)
        .first
        .timeout(const Duration(seconds: 20));
    check(
      cleared.messages.isEmpty && cleared.loadOlder == null,
      'cleared history does not appear on reopen',
    );
    final peerHistory = await bob
        .watchConversation(id)
        .first
        .timeout(const Duration(seconds: 20));
    check(
      peerHistory.messages.length == 4,
      'the other member keeps the shared history',
    );
    const newId = '55555555555555555555555555555555';
    final newHistory = first(
      alice.watchConversation(id),
      (thread) => thread.messages.any((m) => m.id == newId),
    );
    await bob.send(id, 'Tin sau khi xóa', requestId: newId);
    check(
      (await newHistory).messages.single.id == newId,
      'only new messages appear after clearing',
    );
    check(
      (await first(
            alice.watchInbox(),
            (items) =>
                items.any((item) => item.messages.lastOrNull?.id == newId),
          )).single.id ==
          id,
      'a new message returns the conversation to the inbox',
    );
    smokeResult =
        'PASS: $checks real Flutter Firebase SDK communication checks, emulator only.'
            .toJS;
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Communication Firebase SDK: PASS')),
        ),
      ),
    );
  } catch (error) {
    smokeResult = 'FAIL: $error'.toJS;
    runApp(
      const MaterialApp(
        home: Scaffold(body: Text('Communication Firebase SDK failed')),
      ),
    );
  }
}
