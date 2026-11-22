import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_user_store.dart';
import 'recipe_authoring_repository.dart';

class FirestoreRecipeAuthoringRepository implements RecipeAuthoringRepository {
  final FirestoreUserStore store;
  FirestoreRecipeAuthoringRepository(this.store);
  DocumentReference<Map<String, dynamic>> get _draft =>
      store.account.collection('recipe_drafts').doc('current');

  @override
  Future<void> ensureActive() async {
    final account = await store.ensureAccount();
    if (account.isLocked) {
      throw const RecipeAuthoringException(
        'Tài khoản đang bị khóa, không thể đăng công thức.',
      );
    }
  }

  @override
  Future<RecipeDraftRecord> loadDraft() async {
    await ensureActive();
    final proposed = 'r_${store.firestore.collection('recipes').doc().id}';
    final record = await store.firestore.runTransaction((tx) async {
      final snapshot = await tx.get(_draft);
      if (snapshot.exists) {
        final data = snapshot.data()!;
        return RecipeDraftRecord(
          data['submissionId'] as String,
          data['revision'] as int,
          data['draft'] as Map<String, dynamic>?,
          revisionOf: data['revisionOf'] as String?,
        );
      }
      tx.set(_draft, {
        'schemaVersion': 1,
        'authorId': store.uid,
        'submissionId': proposed,
        'revision': 0,
        'draft': null,
        'revisionOf': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return RecipeDraftRecord(proposed, 0, null);
    });
    store.checkSession();
    return record;
  }

  bool _matches(Map<String, dynamic>? current, RecipeDraftRecord record) =>
      current?['submissionId'] == record.submissionId &&
      current?['revision'] == record.revision;

  @override
  Future<int> saveDraft(
    RecipeDraftRecord record,
    Map<String, dynamic> draft,
  ) async {
    store.checkSession();
    final saved = await store.firestore.runTransaction((tx) async {
      final current = await tx.get(_draft);
      if (!_matches(current.data(), record)) return false;
      tx.update(_draft, {
        'draft': draft,
        'revisionOf': record.revisionOf,
        'revision': record.revision + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    store.checkSession();
    if (!saved) {
      throw const RecipeAuthoringException(
        'Bản nháp đã thay đổi trên phiên khác. Hãy mở lại trình soạn.',
      );
    }
    return record.revision + 1;
  }

  @override
  Future<void> submit(
    RecipeDraftRecord record,
    Map<String, dynamic> content,
    String hash,
    String catalogVersion,
  ) async {
    store.checkSession();
    final account = await store.ensureAccount();
    final submission = store.firestore
        .collection('recipes')
        .doc(record.submissionId);
    final outcome = await store.firestore.runTransaction((tx) async {
      final existing = await tx.get(submission);
      final draft = await tx.get(_draft);
      if (existing.exists) {
        return existing.data()?['authorId'] == store.uid &&
                existing.data()?['contentHash'] == hash
            ? 'success'
            : 'content_conflict';
      }
      if (!_matches(draft.data(), record)) return 'draft_conflict';
      final remix = record.remix;
      if (remix != null) {
        final source = await tx.get(
          store.firestore.collection('recipes').doc(remix.recipeId),
        );
        final data = source.data();
        // Không đăng bản sao từ nguồn đã bị ẩn trong lúc người dùng sửa nháp.
        if (data?['status'] != 'approved' ||
            data?['contentHash'] != remix.sourceHash ||
            (data?['content'] as Map?)?['title'] != remix.title ||
            data?['authorId'] != remix.authorId ||
            (data?['author'] as Map?)?['name'] != remix.authorName) {
          return 'source_conflict';
        }
      }
      tx.set(submission, {
        if (record.remix != null) 'remix': record.remix!.toJson(),
        'schemaVersion': 2,
        'id': record.submissionId,
        'authorId': store.uid,
        'author': {
          'id': store.uid,
          'name': account.name,
          'handle': account.handle,
        },
        'isBanner': false,
        'status': 'pending',
        'revisionOf': record.revisionOf,
        'content': content,
        'contentHash': hash,
        'catalogVersion': catalogVersion,
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
        'reviewReason': null,
      });
      tx.delete(_draft);
      return 'success';
    });
    store.checkSession();
    if (outcome == 'source_conflict') {
      throw const RecipeAuthoringException(
        'Công thức gốc không còn công khai. Không thể đăng bản biến tấu này.',
      );
    }
    if (outcome != 'success') {
      throw const RecipeAuthoringException(
        'Bản nháp hoặc bài gửi đã thay đổi. Vui lòng mở lại trình soạn trước khi gửi.',
      );
    }
  }
}
