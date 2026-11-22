import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_user_store.dart';

const recipeReportCategories = {
  'unsafe': 'Hướng dẫn nấu không an toàn',
  'copyright': 'Vi phạm bản quyền',
  'spam': 'Spam hoặc quảng cáo',
  'inappropriate': 'Nội dung không phù hợp',
  'other': 'Lý do khác',
};

class OwnRecipeReport {
  final String status;
  const OwnRecipeReport(this.status);
}

abstract interface class RecipeReportRepository {
  Future<OwnRecipeReport?> own(String recipeId);
  Future<void> submit(String recipeId, String category, String reason);
}

class FirestoreRecipeReportRepository implements RecipeReportRepository {
  final FirestoreUserStore store;
  FirestoreRecipeReportRepository(this.store);
  DocumentReference<Map<String, dynamic>> _report(String recipeId) {
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(recipeId)) {
      throw const FormatException('Mã công thức không hợp lệ.');
    }
    return store.firestore
        .collection('recipe_reports')
        .doc('${store.uid}:$recipeId');
  }

  @override
  Future<OwnRecipeReport?> own(String recipeId) async {
    store.checkSession();
    final snapshot = await _report(recipeId)
        .get(const GetOptions(source: Source.server));
    store.checkSession();
    return snapshot.exists
        ? OwnRecipeReport(snapshot.data()!['status'] as String)
        : null;
  }

  @override
  Future<void> submit(String recipeId, String category, String reason) async {
    store.checkSession();
    final text = reason.trim();
    if (!recipeReportCategories.containsKey(category) ||
        text.isEmpty ||
        text.length > 500) {
      throw const FormatException(
        'Chọn loại báo cáo và nhập lý do từ 1 đến 500 ký tự.',
      );
    }
    final report = _report(recipeId),
        recipe = store.firestore.collection('recipes').doc(recipeId);
    await store.firestore.runTransaction((tx) async {
      final existing = await tx.get(report), post = await tx.get(recipe);
      store.checkSession();
      if (existing.exists) {
        throw const FormatException(
          'Bạn đã báo cáo món này. Không cần gửi lại.',
        );
      }
      if (post.data()?['status'] != 'approved' ||
          post.data()?['authorId'] == store.uid) {
        throw const FormatException(
          'Chỉ báo cáo món công khai của tác giả khác.',
        );
      }
      tx.set(report, {
        'recipeId': recipeId,
        'recipeTitle': (post.data()!['content'] as Map)['title'],
        'reporterId': store.uid,
        'category': category,
        'reason': text,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'resolution': null,
        'resolutionReason': null,
        'resolvedBy': null,
        'resolvedAt': null,
      });
    });
    store.checkSession();
  }
}
