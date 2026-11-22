import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/firestore_user_store.dart';
import '../../auth/services/auth_service.dart';
import '../../cooking_timers/services/cooking_timer_service.dart';
import '../../following/services/following_feed_service.dart';
import '../../fridge/services/fridge_service.dart';
import '../../ingredients/services/ingredient_catalog_service.dart';
import '../../offline_recipes/services/offline_recipe_service.dart';
import '../../recipe_detail/services/recipe_detail_service.dart';
import '../../recipe_reviews/services/recipe_review_repository.dart';
import '../../recipe_reports/services/recipe_report_repository.dart';
import '../../recipe_search/services/recipe_search_service.dart';
import '../../recipe_sharing/services/recipe_sharing_service.dart';
import '../../recipes/services/published_recipe_source.dart';
import '../models/kitchen_entry.dart';
import 'kitchen_repository.dart';
import 'kitchen_local_storage.dart';

class KitchenServices {
  final String uid;
  final KitchenRepository<MealPlanEntry> meals;
  final KitchenRepository<RecipeCollection> collections;
  final KitchenRepository<CookingLog> journal;
  final KitchenRepository<PantryLot> pantry;
  final KitchenRepository<FollowedAuthor> following;
  final CookingTimerService timers;
  final OfflineRecipeService offline;
  final RecipeReviewRepository reviews;
  final RecipeReportRepository? reports;
  final FollowingFeedService Function() createFeed;
  final RecipeSharingService sharing;
  final RecipeSearchService search;
  final RecipeDetailService details;
  final IngredientCatalogService catalog;
  final FridgeService fridge;
  const KitchenServices({
    required this.uid,
    required this.meals,
    required this.collections,
    required this.journal,
    required this.pantry,
    required this.following,
    required this.timers,
    required this.offline,
    required this.reviews,
    this.reports,
    required this.createFeed,
    required this.sharing,
    required this.search,
    required this.details,
    required this.catalog,
    required this.fridge,
  });
  bool get signedIn => uid.isNotEmpty;
}

class KitchenScope extends InheritedWidget {
  final KitchenServices services;
  const KitchenScope({super.key, required this.services, required super.child});
  static KitchenServices? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitchenScope>()?.services;
  static KitchenServices of(BuildContext context) =>
      maybeOf(context) ?? (throw StateError('KitchenServices chưa được cấp.'));
  @override
  bool updateShouldNotify(KitchenScope oldWidget) =>
      oldWidget.services != services;
}

/// Vòng đời gắn với scope UID của App; route không tự tạo lại cache/timer.
class KitchenSessionHost extends StatefulWidget {
  final Widget child;
  const KitchenSessionHost({super.key, required this.child});
  @override
  State<KitchenSessionHost> createState() => _KitchenSessionHostState();
}

class _KitchenSessionHostState extends State<KitchenSessionHost> {
  KitchenServices? _services;
  late AuthService _auth;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    _auth = context.read<AuthService>();
    final store = context.read<FirestoreUserStore>();
    final published = context.read<PublishedRecipeSource>();
    final details = context.read<RecipeDetailService>();
    final local = PreferencesKitchenStorage();
    final prefix =
        'bepxinh.kitchen.v1.${sha256.convert(utf8.encode(store.uid))}';
    _services = KitchenServices(
      uid: store.uid,
      meals: FirestoreKitchenRepository(
        store: store,
        collection: 'meal_plans',
        decode: MealPlanEntry.fromJson,
      ),
      collections: FirestoreKitchenRepository(
        store: store,
        collection: 'recipe_collections',
        decode: RecipeCollection.fromJson,
      ),
      journal: FirestoreKitchenRepository(
        store: store,
        collection: 'cooking_logs',
        decode: CookingLog.fromJson,
      ),
      pantry: FirestoreKitchenRepository(
        store: store,
        collection: 'pantry_lots',
        decode: PantryLot.fromJson,
      ),
      following: FirestoreKitchenRepository(
        store: store,
        collection: 'following',
        decode: FollowedAuthor.fromJson,
      ),
      timers: CookingTimerService(
        storage: local,
        storageKey: '$prefix.timers',
        checkSession: store.checkSession,
      ),
      offline: OfflineRecipeService(
        storage: local,
        storageKey: '$prefix.offline',
        checkSession: store.checkSession,
        client: context.read<http.Client>(),
        isPublished: (id) async {
          if (id.startsWith('r_')) {
            try {
              return await published.find(id, server: true) != null;
            } on FirebaseException catch (error) {
              // Bài bị ẩn có thể trả permission-denied thay vì document; coi là đã thu hồi quyền đọc.
              if (error.code == 'permission-denied' ||
                  error.code == 'not-found') {
                return false;
              }
              rethrow;
            }
          }
          try {
            return (await details.fetchRecipe(id)).recipe.id == id;
          } on RecipeNotFoundException {
            return false;
          }
        },
      ),
      reviews: FirestoreRecipeReviewRepository(store),
      reports: FirestoreRecipeReportRepository(store),
      createFeed: () => FirestoreFollowingFeedService(published),
      sharing: RecipeSharingService(),
      search: context.read<RecipeSearchService>(),
      details: details,
      catalog: context.read<IngredientCatalogService>(),
      fridge: context.read<FridgeService>(),
    );
    if (store.uid.isNotEmpty) {
      unawaited(
        _services!.timers.load().catchError((Object _, StackTrace _) {}),
      );
    }
  }

  @override
  void dispose() {
    final services = _services;
    if (services != null) {
      // Cache riêng được xóa khi đổi tài khoản; mỗi UID luôn có namespace riêng.
      if (_auth.userId != services.uid) {
        unawaited(
          Future.wait([services.offline.clear(), services.timers.clear()])
              .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
        );
      }
      services.timers.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KitchenScope(services: _services!, child: widget.child);
}
