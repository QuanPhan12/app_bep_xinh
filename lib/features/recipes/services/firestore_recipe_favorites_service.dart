import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_user_store.dart';
import 'recipe_favorites_service.dart';

class FirestoreRecipeFavoritesService implements RecipeFavoritesService {
  final FirestoreUserStore store;
  final _changes = StreamController<RecipeFavoriteChange>.broadcast();
  final _values = <String>{};
  Future<void>? _loadTask;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool _disposed = false;

  FirestoreRecipeFavoritesService(this.store);

  @override
  Stream<RecipeFavoriteChange> get changes => _changes.stream;

  Future<void> _load() =>
      _loadTask ??= _loadInitial().catchError((Object error) {
        _loadTask = null;
        throw error;
      });

  Future<void> _loadInitial() async {
    store.checkSession();
    final snapshot = await store.favorites.get();
    store.checkSession();
    if (_disposed) return;
    _values.addAll(snapshot.docs.map((doc) => doc.id));
    _subscription = store.favorites.snapshots().listen(
      (snapshot) {
        if (_disposed || store.auth.currentUser?.uid != store.uid) return;
        final next = snapshot.docs.map((doc) => doc.id).toSet();
        for (final id in {..._values, ...next}) {
          if (_values.contains(id) != next.contains(id)) {
            _changes.add(RecipeFavoriteChange(id, next.contains(id)));
          }
        }
        _values
          ..clear()
          ..addAll(next);
      },
      onError: (Object _) {
        // Lỗi mạng của listener không biến thành thao tác bỏ lưu.
      },
    );
  }

  @override
  Future<bool> isFavorite(String recipeId, {required bool fallback}) async {
    if (store.uid.isEmpty) return false;
    await _load();
    store.checkSession();
    return _values.contains(recipeId);
  }

  @override
  Future<void> setFavorite(String recipeId, bool value) async {
    if (recipeId.isEmpty || recipeId.contains('/')) {
      throw ArgumentError('Invalid recipe id');
    }
    await _load();
    store.checkSession();
    final doc = store.favorites.doc(recipeId);
    final recipe = store.firestore.collection('recipes').doc(recipeId);
    await store.firestore.runTransaction((transaction) async {
      final previous = await transaction.get(doc);
      store.checkSession();
      if (previous.exists == value) return;
      // ID bài đã đăng dùng r_; bài mẫu chỉ theo dõi nếu có document công thức thật.
      final tracked =
          recipeId.startsWith('r_') || (await transaction.get(recipe)).exists;
      if (value) {
        transaction.set(doc, {
          'recipeId': recipeId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.delete(doc);
      }
      if (tracked) {
        // Increment và favorite cùng commit; rules xác minh delta theo trước/sau.
        transaction.set(recipe, {
          'engagement': {
            'likeCount': FieldValue.increment(value ? 1 : -1),
            'shareCount': FieldValue.increment(0),
          },
        }, SetOptions(merge: true));
      }
    });
    store.checkSession();
    if (_disposed) return;
    if (value) {
      _values.add(recipeId);
    } else {
      _values.remove(recipeId);
    }
    _changes.add(RecipeFavoriteChange(recipeId, value));
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
    await _changes.close();
  }
}
