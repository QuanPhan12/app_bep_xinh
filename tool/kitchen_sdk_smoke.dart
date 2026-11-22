import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_bep_xinh/core/services/firestore_user_store.dart';
import 'package:app_bep_xinh/features/kitchen/models/kitchen_entry.dart';
import 'package:app_bep_xinh/features/kitchen/services/kitchen_repository.dart';
import 'package:app_bep_xinh/features/recipe_reviews/services/recipe_review_repository.dart';
import 'package:app_bep_xinh/features/following/services/following_feed_service.dart';
import 'package:app_bep_xinh/features/recipes/services/published_recipe_source.dart';

@JS('firebaseSmokeResult')
external JSString? get result;
@JS('firebaseSmokeResult')
external set result(JSString? value);
int checks = 0;
void check(bool value, String label) {
  if (!value) throw StateError(label);
  checks++;
}

Future<void> handshake(String command) async {
  result = command.toJS;
  for (var i = 0; result?.toDart != 'KITCHEN_READY'; i++) {
    if (i > 40) throw StateError('Harness timed out');
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  result = 'running'.toJS;
  try {
    final app = await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'demo-key',
        appId: '1:123456789:web:abcdef',
        messagingSenderId: '123456789',
        projectId: 'demo-bepxinh',
      ),
    );
    final auth = FirebaseAuth.instanceFor(app: app),
        db = FirebaseFirestore.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9199);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8180);
    await auth.createUserWithEmailAndPassword(
      email: 'kitchen-${DateTime.now().microsecondsSinceEpoch}@example.test',
      password: 'EmulatorOnly123!',
    );
    await auth.currentUser!.updateDisplayName('Alice');
    final store = FirestoreUserStore(
      firestore: db,
      auth: auth,
      uid: auth.currentUser!.uid,
    );
    await store.ensureAccount();
    final uid = store.uid;
    await handshake('KITCHEN_SEED:$uid');
    final meals = FirestoreKitchenRepository(
      store: store,
      collection: 'meal_plans',
      decode: MealPlanEntry.fromJson,
    );
    const ref = RecipeRef(
      id: 'r_kitchen_00',
      title: 'Meal',
      authorId: 'kitchen_author_00',
    );
    await meals.save(
      const MealPlanEntry(
        id: 'meal',
        day: '2026-11-16',
        slot: MealSlot.lunch,
        recipe: ref,
        servings: 2,
      ),
    );
    check((await meals.fetch()).single.servings == 2, 'meal server save/read');
    final observed = meals
        .watch()
        .firstWhere((items) => items.single.servings == 4)
        .timeout(const Duration(seconds: 15));
    await meals.update(
      'meal',
      (current) => MealPlanEntry(
        id: current.id,
        day: current.day,
        slot: current.slot,
        recipe: current.recipe,
        servings: 4,
      ),
    );
    check(
      (await observed).single.servings == 4,
      'meal watch server acknowledgement',
    );
    final collections = FirestoreKitchenRepository(
      store: store,
      collection: 'recipe_collections',
      decode: RecipeCollection.fromJson,
    );
    await collections.save(
      RecipeCollection(id: 'group', name: 'Weekend', recipeIds: []),
    );
    await Future.wait(
      ['r_kitchen_00', 'r_kitchen_01'].map(
        (id) => collections.update(
          'group',
          (current) => RecipeCollection(
            id: current.id,
            name: current.name,
            recipeIds: {...current.recipeIds, id}.toList(),
          ),
        ),
      ),
    );
    check(
      (await collections.fetch()).single.recipeIds.length == 2,
      'concurrent transaction additions retained',
    );
    final journal = FirestoreKitchenRepository(
      store: store,
      collection: 'cooking_logs',
      decode: CookingLog.fromJson,
    );
    for (var i = 0; i < 2; i++) {
      await journal.save(
        CookingLog(
          id: 'session',
          recipe: ref,
          day: '2026-11-16',
          servings: 2,
          note: '$i',
        ),
      );
    }
    check(
      await journal.count() == 1,
      'aggregate count from idempotent session',
    );
    final pantry = FirestoreKitchenRepository(
      store: store,
      collection: 'pantry_lots',
      decode: PantryLot.fromJson,
    );
    await pantry.save(
      const PantryLot(
        id: 'egg',
        ingredientId: 'egg',
        name: 'Egg',
        amount: 2,
        unitId: 'fruit',
      ),
    );
    await pantry.update(
      'egg',
      (current) => current.withAmount(current.amount! - 1),
    );
    check(
      (await pantry.fetch()).single.amount == 1,
      'pantry transaction quantity',
    );
    final following = FirestoreKitchenRepository(
      store: store,
      collection: 'following',
      decode: FollowedAuthor.fromJson,
    );
    final authors = List.generate(
      11,
      (i) => FollowedAuthor(
        id: 'kitchen_author_${i.toString().padLeft(2, '0')}',
        name: 'Author $i',
      ),
    );
    for (final author in authors) {
      await following.save(author);
    }
    check((await following.fetch()).length == 11, 'follow owners only');
    final feed = FirestoreFollowingFeedService(PublishedRecipeSource(db));
    final a = await feed.next(authors),
        b = await feed.next(authors),
        c = await feed.next(authors);
    final ids = [...a, ...b, ...c].map((item) => item.id).toList();
    check(
      a.length == 20 && b.length == 5 && c.isEmpty,
      'following feed pages across two author groups',
    );
    check(
      ids.toSet().length == 25 && !feed.hasMore,
      'following feed unique complete',
    );
    check(
      ids.first == 'r_kitchen_24' && ids.last == 'r_kitchen_00',
      'timestamp ties sorted by document ID',
    );
    final reviews = FirestoreRecipeReviewRepository(store);
    await reviews.submit(ref.id, 4, 'Good');
    check(
      (await reviews.own(ref.id))?.status == 'pending',
      'review own pending',
    );
    check(
      (await reviews.page(ref.id)).items.isEmpty,
      'pending review excluded',
    );
    await handshake('KITCHEN_APPROVE:$uid');
    final summary = await reviews
        .ratings(ref.id)
        .firstWhere((rating) => rating.count == 24)
        .timeout(const Duration(seconds: 15));
    check(summary.average == 4, 'trusted review aggregate');
    final first = await reviews.page(ref.id),
        second = await reviews.page(ref.id, after: first.next);
    check(
      first.items.length == 20 && second.items.length == 4,
      'review cursor preserves submillisecond timestamp',
    );
    check(
      {
            ...first.items.map((r) => r.uid),
            ...second.items.map((r) => r.uid),
          }.length ==
          24,
      'review page IDs unique',
    );
    await reviews.submit(ref.id, 5, 'Updated');
    check(
      (await reviews.ratings(ref.id).firstWhere((r) => r.count == 23)).sum ==
          92,
      'editing withdraws old aggregate',
    );
    await reviews.delete(ref.id);
    check(await reviews.own(ref.id) == null, 'delete review transaction');
    await meals.delete('meal');
    check(await meals.count() == 0, 'delete meal');
    await auth.signOut();
    var rejected = false;
    try {
      await journal.fetch();
    } catch (_) {
      rejected = true;
    }
    check(rejected, 'old UID store rejected after logout');
    result = 'PASS: $checks Flutter kitchen SDK checks'.toJS;
  } catch (error, stack) {
    result = 'FAIL: $error\n$stack'.toJS;
  }
  runApp(const SizedBox.shrink());
}
