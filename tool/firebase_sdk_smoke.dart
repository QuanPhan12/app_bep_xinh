import 'dart:js_interop';
import 'meal_sdk_smoke.dart';
import 'nutrition_sdk_smoke.dart';

import 'package:http/http.dart' as http;
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_cover_picker.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/cloudinary_recipe_image_uploader.dart';

import 'package:app_bep_xinh/core/services/firestore_user_store.dart';
import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/features/auth/services/firebase_auth_service.dart';
import 'package:app_bep_xinh/features/profile/services/firestore_profile_service.dart';
import 'package:app_bep_xinh/features/recipes/services/firestore_recipe_favorites_service.dart';
import 'package:app_bep_xinh/features/recipe_sharing/services/recipe_share_recorder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:app_bep_xinh/features/ingredients/services/firestore_ingredient_catalog_service.dart';

@JS('firebaseSmokeResult')
external set smokeResult(JSString value);

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Entry point kiểm thử cố định project demo và loopback; không dùng cấu hình project thật.
  smokeResult = 'running'.toJS;
  try {
    final app = await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'demo-key',
        appId: '1:123456789:web:abcdef',
        messagingSenderId: '123456789',
        projectId: 'demo-bepxinh',
      ),
    );
    final sdkAuth = FirebaseAuth.instanceFor(app: app);
    final db = FirebaseFirestore.instanceFor(app: app);
    await sdkAuth.useAuthEmulator('127.0.0.1', 9099);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8080);
    final catalog = await FirestoreIngredientCatalogService(db).fetchCatalog();
    check(
      catalog.ingredients.length == 231 && catalog.categories.length == 15,
      'Firestore ingredient catalog',
    );
    check(
      catalog.byId['tofu']!.group == 'Đậu và các loại hạt',
      'category resolved',
    );
    final auth = FirebaseAuthService(
      sdkAuth,
      prepareUser: (user) async {
        await FirestoreUserStore(
          firestore: db,
          auth: sdkAuth,
          uid: user.uid,
        ).ensureAccount();
      },
    );
    final email = 'cook-${DateTime.now().microsecondsSinceEpoch}@example.test';
    await auth.register('Đầu bếp', email, ' secret-123 ');
    final uid = auth.userId!;
    // Kiểm tra ngay sau đăng ký, trước khi mở Profile hoặc tự gọi ensureAccount.
    final registered = await db
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    check(
      registered.exists && registered.data()?['name'] == 'Đầu bếp',
      'registration creates Firestore user immediately',
    );
    final store = FirestoreUserStore(firestore: db, auth: sdkAuth, uid: uid);
    final favorites = FirestoreRecipeFavoritesService(store);
    final imageClient = http.Client();
    final profile = FirestoreProfileService(
      store: store,
      catalog: MockApiClient(latency: Duration.zero),
      favorites: favorites,
      avatarPicker: ImagePickerRecipeCoverPicker(),
      avatarUploader: CloudinaryRecipeImageUploader(imageClient),
    );
    check(
      (await profile.fetchAccount()).name == 'Đầu bếp',
      'registration name',
    );
    check(
      (await profile.updateProfile(
            name: 'Bếp mới',
            bio: 'Nấu ăn mỗi ngày',
          )).bio ==
          'Nấu ăn mỗi ngày',
      'profile update',
    );
    await profile.setShowBio(false);
    await favorites.setFavorite('tofu_tomato', true);
    check(
      await favorites.isFavorite('tofu_tomato', fallback: false),
      'favorite save',
    );
    await favorites.setFavorite('r_sdk_engagement', true);
    await favorites.setFavorite('r_sdk_engagement', true);
    var engagement =
        (await db.doc('recipes/r_sdk_engagement').get()).data()!['engagement']
            as Map;
    check(engagement['likeCount'] == 1, 'atomic favorite deduplication');
    await favorites.setFavorite('r_sdk_engagement', false);
    final recorder = RecipeShareRecorder(store);
    await recorder.record('r_sdk_engagement', 'copy');
    await recorder.record('r_sdk_engagement', 'sheet');
    engagement =
        (await db.doc('recipes/r_sdk_engagement').get()).data()!['engagement']
            as Map;
    check(
      engagement['likeCount'] == 0 && engagement['shareCount'] == 1,
      'atomic favorite removal and unique share',
    );
    final data = await profile.fetchProfile();
    check(data.ownRecipes.isEmpty, 'no demo authorship assigned to real UID');
    check(data.savedRecipes.single.id == 'tofu_tomato', 'saved tab');
    await mealSdkSmoke(store);
    await nutritionSdkSmoke(store);
    await profile.dispose();
    await favorites.dispose();
    await auth.signOut();
    await auth.signIn(email, ' secret-123 ');
    check(auth.userId == uid, 'sign-in UID');
    final reopened = FirestoreRecipeFavoritesService(store);
    check((await store.ensureAccount()).name == 'Bếp mới', 'name persistence');
    check(!(await store.ensureAccount()).showBio, 'visibility persistence');
    check(
      await reopened.isFavorite('tofu_tomato', fallback: false),
      'favorite persistence',
    );
    await reopened.setFavorite('tofu_tomato', false);
    check(
      !await reopened.isFavorite('tofu_tomato', fallback: true),
      'favorite removal',
    );
    await auth.signOut();
    await auth.register('Người khác', 'other-$email', 'secret-456');
    var sessionRejected = false;
    try {
      await store.ensureAccount();
    } on StateError {
      sessionRejected = true;
    }
    check(sessionRejected, 'stale account session rejected');
    var accessRejected = false;
    try {
      await db.collection('users').doc(uid).get();
    } on FirebaseException catch (error) {
      accessRejected = error.code == 'permission-denied';
    }
    check(accessRejected, 'cross-account access denied by rules');
    final secondStore = FirestoreUserStore(
      firestore: db,
      auth: sdkAuth,
      uid: auth.userId!,
    );
    check(
      (await secondStore.ensureAccount()).name == 'Người khác',
      'second account isolated',
    );
    await reopened.dispose();
    imageClient.close();
    await auth.signOut();
    auth.dispose();
    smokeResult = 'PASS: Flutter Firebase SDK profile/favorites, meal progress, concurrent completion/stock idempotency, rollback, shopping and account isolation'
        .toJS;
  } catch (error) {
    smokeResult = 'FAIL: $error'.toJS;
  }
  runApp(
    const MaterialApp(
      home: Scaffold(body: Center(child: Text('Firebase SDK smoke completed'))),
    ),
  );
}
