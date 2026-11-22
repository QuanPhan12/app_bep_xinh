import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_user_store.dart';
import '../../kitchen/models/kitchen_entry.dart';

class RecipeReview {
  final String uid;
  final String name;
  final int stars;
  final String body;
  final String status;
  final DateTime updatedAt;
  const RecipeReview({
    required this.uid,
    required this.name,
    required this.stars,
    required this.body,
    required this.status,
    required this.updatedAt,
  });
  factory RecipeReview.fromJson(String uid, Map<String, dynamic> data) =>
      RecipeReview(
        uid: uid,
        name: kitchenText(data['name'], 60),
        stars: kitchenInt(data['stars'], 1, 5),
        body: kitchenText(data['body'], 1000, empty: true),
        status: data['status'] as String,
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
}

class RatingSummary {
  final int sum, count;
  const RatingSummary({this.sum = 0, this.count = 0});
  double? get average => count == 0 ? null : sum / count;
}

class ReviewPage {
  final List<RecipeReview> items;
  final String? next;
  const ReviewPage(this.items, this.next);
}

abstract interface class RecipeReviewRepository {
  String get uid;
  Future<ReviewPage> page(String recipeId, {String? after});
  Future<RecipeReview?> own(String recipeId);
  Stream<RatingSummary> ratings(String recipeId);
  Future<void> submit(String recipeId, int stars, String body);
  Future<void> delete(String recipeId);
  Future<void> report(String recipeId, String reviewerId, String reason);
}

class FirestoreRecipeReviewRepository implements RecipeReviewRepository {
  final FirestoreUserStore store;
  FirestoreRecipeReviewRepository(this.store);
  @override
  String get uid => store.uid;
  DocumentReference<Map<String, dynamic>> _recipe(String id) =>
      store.firestore.collection('recipes').doc(kitchenKey(id));
  @override
  Future<ReviewPage> page(String recipeId, {String? after}) async {
    var query = _recipe(recipeId)
        .collection('user_reviews')
        .where('status', isEqualTo: 'approved')
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(20);
    if (after != null) {
      final cursor = jsonDecode(after) as List;
      query = query.startAfter([
        Timestamp(cursor[0] as int, cursor[1] as int),
        cursor[2] as String,
      ]);
    }
    final snapshot = await query.get(const GetOptions(source: Source.server));
    final items = snapshot.docs
        .map((doc) => RecipeReview.fromJson(doc.id, doc.data()))
        .toList();
    final last = snapshot.docs.lastOrNull;
    final stamp = last?.data()['updatedAt'] as Timestamp?;
    return ReviewPage(
      items,
      items.length == 20 && last != null && stamp != null
          ? jsonEncode([stamp.seconds, stamp.nanoseconds, last.id])
          : null,
    );
  }

  @override
  Future<RecipeReview?> own(String recipeId) async {
    store.checkSession();
    final doc = await _recipe(recipeId)
        .collection('user_reviews')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    store.checkSession();
    return doc.exists ? RecipeReview.fromJson(uid, doc.data()!) : null;
  }

  @override
  Stream<RatingSummary> ratings(String recipeId) => _recipe(recipeId)
      .collection('ratings')
      .doc('summary')
      .snapshots()
      .where((snapshot) => !snapshot.metadata.hasPendingWrites)
      .map((snapshot) {
        final data = snapshot.data();
        return data == null
            ? const RatingSummary()
            : RatingSummary(
                sum: data['sum'] as int,
                count: data['count'] as int,
              );
      });
  Future<void> _write(String recipeId, int? stars, String body) async {
    store.checkSession();
    if (stars != null) kitchenInt(stars, 1, 5);
    final text = kitchenText(body, 1000, empty: true);
    final profile = await store.ensureAccount();
    final recipe = _recipe(recipeId),
        review = _recipe(recipeId).collection('user_reviews').doc(uid),
        summary = _recipe(recipeId).collection('ratings').doc('summary');
    await store.firestore.runTransaction((transaction) async {
      final post = await transaction.get(recipe),
          old = await transaction.get(review),
          aggregate = await transaction.get(summary);
      store.checkSession();
      if (post.data()?['status'] != 'approved' ||
          post.data()?['authorId'] == uid) {
        throw const FormatException(
          'Chỉ đánh giá công thức công khai của tác giả khác.',
        );
      }
      final oldData = old.data();
      final previous = oldData?['status'] == 'approved'
          ? (oldData!['stars'] as int)
          : 0;
      final sum = (aggregate.data()?['sum'] as int? ?? 0) - previous;
      final count =
          (aggregate.data()?['count'] as int? ?? 0) - (previous > 0 ? 1 : 0);
      if (stars == null) {
        if (!old.exists) return;
        transaction.delete(review);
      } else {
        transaction.set(review, {
          'uid': uid,
          'name': profile.name,
          'stars': stars,
          'body': text,
          'status': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      // Rules kiểm tra delta với review trước/sau trong cùng commit, không tin số client gửi.
      transaction.set(summary, {
        'sum': sum,
        'count': count,
        'lastReviewerId': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    store.checkSession();
  }

  @override
  Future<void> submit(String recipeId, int stars, String body) =>
      _write(recipeId, stars, body);
  @override
  Future<void> delete(String recipeId) => _write(recipeId, null, '');
  @override
  Future<void> report(String recipeId, String reviewerId, String reason) async {
    store.checkSession();
    final text = kitchenText(reason, 500);
    await _recipe(recipeId)
        .collection('user_reviews')
        .doc(kitchenKey(reviewerId))
        .collection('reports')
        .doc(uid)
        .set({'reason': text, 'updatedAt': FieldValue.serverTimestamp()});
    store.checkSession();
  }
}
