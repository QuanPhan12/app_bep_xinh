import 'dart:convert';
import 'dart:js_interop';

import 'package:app_bep_xinh/core/services/firestore_user_store.dart';
import 'package:app_bep_xinh/core/services/mock_api_client.dart';
import 'package:app_bep_xinh/features/auth/services/auth_service.dart';
import 'package:app_bep_xinh/features/ingredients/services/firestore_ingredient_catalog_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/models/recipe_draft.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/firestore_recipe_authoring_repository.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/firestore_recipe_editor_service.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/cloudinary_recipe_image_uploader.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_image_uploader.dart';
import 'package:app_bep_xinh/features/recipe_editor/services/recipe_authoring_repository.dart';
import 'package:app_bep_xinh/features/recipes/services/published_recipe_source.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:app_bep_xinh/features/home/cubits/home/home.dart';
import 'package:app_bep_xinh/features/home/services/home_service.dart';
import 'package:app_bep_xinh/features/recipes/services/firestore_recipe_favorites_service.dart';
import 'package:app_bep_xinh/features/fridge/services/remote_fridge_service.dart';
import 'package:app_bep_xinh/features/fridge/services/firestore_fridge_inventory_repository.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

@JS('firebaseSmokeResult')
external set smokeResult(JSString value);
void check(bool value, String label) {
  if (!value) throw StateError(label);
}

class _FixtureUploader implements RecipeImageUploader {
  @override
  Future<RecipeImage> upload(RecipeImage image) async => image.url != null
      ? image
      : RecipeImage.remote(
          id: image.id,
          name: image.name,
          url: 'https://res.cloudinary.com/ddqouziau/image/upload/v1/sdk_fixture.webp',
          publicId: 'sdk_fixture',
        );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  smokeResult = 'running'.toJS;
  var phase = 'initialize';
  final client = http.Client();
  try {
    final app = await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'demo-key',
        appId: '1:123456789:web:abcdef',
        messagingSenderId: '123456789',
        projectId: 'demo-bepxinh',
      ),
    );
    final authSdk = FirebaseAuth.instanceFor(app: app),
        db = FirebaseFirestore.instanceFor(app: app);
    await authSdk.useAuthEmulator('127.0.0.1', 9099);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8080);
    phase = 'auth';
    final credential = await authSdk.createUserWithEmailAndPassword(
      email: 'publish-${DateTime.now().microsecondsSinceEpoch}@example.test',
      password: 'demo-password-123',
    );
    await credential.user!.updateDisplayName('SDK cook');
    final store = FirestoreUserStore(
      firestore: db,
      auth: authSdk,
      uid: authSdk.currentUser!.uid,
    );
    await store.ensureAccount();
    final catalog = FirestoreIngredientCatalogService(db);
    final RecipeImageUploader uploader =
        const bool.fromEnvironment('LIVE_CLOUDINARY_SMOKE')
        ? CloudinaryRecipeImageUploader(client, uploadTag: 'bep_xinh_sdk_smoke')
        : _FixtureUploader();
    final repository = FirestoreRecipeAuthoringRepository(store);
    final service = FirestoreRecipeEditorService(
      repository: repository,
      uploader: uploader,
      catalog: catalog,
    );
    phase = 'stage_0';
    check(await service.loadDraft() == null, 'new draft');
    final source = await MockApiClient(latency: Duration.zero)
        .get('recipe_details');
    final content = RecipeContent.fromJson(
      (source['recipes'] as List).first as Map<String, dynamic>,
      await catalog.fetchCatalog(),
    );
    final bytes = (await rootBundle.load(
      'assets/images/fridge_tofu_tomato.webp',
    )).buffer.asUint8List();
    final baseDraft = RecipeDraft.fromContent(content);
    final draft = baseDraft.copyWith(
      title: 'SDK publishing test',
      cover: RecipeCover(id: 'sdk-cover', name: 'food.webp', bytes: bytes),
      steps: baseDraft.steps
          .map(
            (step) => step.photo == null
                ? step
                : step.copyWith(
                    photo: RecipeCover(
                      id: 'sdk-${step.id}',
                      name: 'step.webp',
                      bytes: bytes,
                    ),
                  ),
          )
          .toList(),
    );
    phase = 'stage_1';
    await service.saveDraft(draft);
    final raw = await store.account
        .collection('recipe_drafts')
        .doc('current')
        .get();
    check(
      !jsonEncode(raw.data()!['draft']).contains('bytesBase64'),
      'no image data in Firestore',
    );
    final id = raw.data()!['submissionId'] as String;
    final reopened = FirestoreRecipeEditorService(
      repository: FirestoreRecipeAuthoringRepository(store),
      uploader: uploader,
      catalog: catalog,
    );
    phase = 'stage_2';
    final restored = await reopened.loadDraft();
    check(
      restored?.cover?.url != null,
      'draft restored from Cloudinary reference',
    );
    phase = 'stage_3';
    final stale = await repository.loadDraft();
    await reopened.saveDraft(
      restored!.copyWith(description: 'Saved on second session'),
    );
    phase = 'stage_4';
    var conflict = false;
    try {
      await repository.saveDraft(stale, {});
    } on RecipeAuthoringException {
      conflict = true;
    }
    check(conflict, 'revision conflict detected');
    final toSubmit = restored.copyWith(description: 'Saved on second session');
    phase = 'stage_5';
    await reopened.submit(toSubmit);
    await reopened.submit(toSubmit);
    final submission = db.collection('recipes').doc(id);
    final pending = await submission.get();
    check(pending.data()?['status'] == 'pending', 'pending only');
    check(
      !(await store.account.collection('recipe_drafts').doc('current').get())
          .exists,
      'draft removed atomically',
    );
    phase = 'stage_6';
    final public = PublishedRecipeSource(db);
    check(await public.find(id) == null, 'pending hidden from public catalog');
    check(
      !(await public.fetchBanners()).any((entry) => entry['id'] == id),
      'pending banner hidden',
    );
    final manualApproved = public
        .watchPublished()
        .firstWhere((entries) => entries.any((entry) => entry['id'] == id))
        .timeout(const Duration(seconds: 45));
    smokeResult = 'MANUAL_APPROVE:$id'.toJS;
    await submission
        .snapshots()
        .firstWhere((s) => s.data()?['status'] == 'approved')
        .timeout(const Duration(seconds: 45));
    await manualApproved;
    final published = await public.find(id);
    check(published?['isBanner'] == false, 'author cannot select banner');
    check(
      !(await public.fetchBanners()).any((entry) => entry['id'] == id),
      'only admin-selected recipes become banners',
    );
    check(
      published?['title'] == 'SDK publishing test',
      'approved recipe discoverable',
    );
    check(
      (await public.forAuthor(store.uid)).any((r) => r['id'] == id),
      'approved author recipes',
    );
    phase = 'fridge_remote';
    RemoteFridgeService fridgeService() => RemoteFridgeService(
      inventory: FirestoreFridgeInventoryRepository(store),
      catalog: catalog,
      readPublished: public.fetchPublished,
    );
    final fridge = fridgeService();
    check((await fridge.fetchFridge()).selectedIds.isEmpty, 'new fridge empty');
    await fridge.saveInventory(['egg', 'tomato']);
    final secondFridge = fridgeService();
    final fridgeRestored = await secondFridge.fetchFridge();
    check(
      fridgeRestored.selectedIds.toSet().containsAll(['egg', 'tomato']),
      'inventory persisted across instances',
    );
    check(
      fridgeRestored.recipes.any(
        (r) => r.id == id && r.image?.startsWith('https://') == true,
      ),
      'fridge reads approved Cloudinary recipe',
    );
    await secondFridge.saveInventory([]);
    check((await fridge.fetchFridge()).selectedIds.isEmpty, 'clear persisted');
    phase = 'home_realtime';
    final favorites = FirestoreRecipeFavoritesService(store);
    final liveHome = HomeCubit(
      service: MockHomeService(
        MockApiClient(latency: Duration.zero),
        fridge,
        favorites,
        published: public,
      ),
    );
    await liveHome.loadHome();
    check(
      liveHome.state.recipes.any((r) => r.id == id),
      'home remote initial recipe',
    );
    final bannerOn = liveHome.stream
        .firstWhere(
          (s) =>
              s.data!.banners.any((b) => b.id == id) &&
              s.recipes.any(
                (r) => r.id == id && r.title == 'Realtime admin update',
              ),
        )
        .timeout(const Duration(seconds: 30));
    smokeResult = 'LIVE_BANNER_ON:$id'.toJS;
    await bannerOn;
    final bannerOff = liveHome.stream
        .firstWhere((s) => !s.data!.banners.any((b) => b.id == id))
        .timeout(const Duration(seconds: 30));
    smokeResult = 'LIVE_BANNER_OFF:$id'.toJS;
    await bannerOff;
    final removed = liveHome.stream
        .firstWhere(
          (s) =>
              !s.recipes.any((r) => r.id == id) &&
              !s.data!.banners.any((b) => b.id == id),
        )
        .timeout(const Duration(seconds: 30));
    smokeResult = 'LIVE_RECIPE_REMOVE:$id'.toJS;
    await removed;
    await liveHome.close();
    await favorites.dispose();
    await fridge.dispose();
    await secondFridge.dispose();
    await authSdk.signOut();
    smokeResult = 'PASS: Firestore publishing, remote fridge, realtime Home title/banner changes and recipe removal without refresh'
        .toJS;
  } catch (error, stack) {
    smokeResult =
        'FAIL: $phase ${error is AuthFailure ? error.message : error} $stack'
            .toJS;
  } finally {
    client.close();
  }
  runApp(
    const MaterialApp(
      home: Scaffold(body: Text('Recipe publishing smoke completed')),
    ),
  );
}
