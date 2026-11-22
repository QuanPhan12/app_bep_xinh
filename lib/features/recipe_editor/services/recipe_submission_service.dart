import '../../recipes/models/recipe_remix.dart';
import '../../../core/services/firestore_user_store.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe_submission.dart';
import '../models/recipe_draft.dart';
import '../../ingredients/services/ingredient_catalog_service.dart';
import 'recipe_draft_codec.dart';
import 'recipe_authoring_repository.dart';

abstract interface class RecipeSubmissionService {
  Future<List<RecipeSubmission>> fetchOwn();
  Future<void> createRevision(String id);
  Future<void> changeVisibility(
    RecipeSubmission expected,
    RecipeVisibilityAction action,
  );
}

class FirestoreRecipeSubmissionService implements RecipeSubmissionService {
  final FirestoreUserStore store;
  final IngredientCatalogService catalog;
  FirestoreRecipeSubmissionService(this.store, this.catalog);
  @override
  Future<void> changeVisibility(
    RecipeSubmission expected,
    RecipeVisibilityAction action,
  ) async {
    store.checkSession();
    final ref = store.firestore.collection('recipes').doc(expected.id);
    final event = ref.collection('visibility_events').doc();
    await store.firestore.runTransaction((tx) async {
      store.checkSession();
      final snapshot = await tx.get(ref);
      final data = snapshot.data();
      if (action == RecipeVisibilityAction.delete &&
          expected.status == RecipeSubmissionStatus.rejected) {
        final draft = await tx.get(
          store.account.collection('recipe_drafts').doc('current'),
        );
        // Giữ nguồn revisionOf cho đến khi bản sửa được gửi để không làm kẹt nháp đang có.
        if (draft.data()?['revisionOf'] == expected.id &&
            draft.data()?['draft'] != null) {
          throw const RecipeAuthoringException(
            'Bạn đang có bản nháp sửa bài này. Hãy gửi bản nháp trước khi xóa bài gốc.',
          );
        }
      }
      if (data == null ||
          data['authorId'] != store.uid ||
          data['status'] != expected.status.name ||
          data['visibilityEventId'] != expected.visibilityEventId) {
        throw const RecipeAuthoringException(
          'Bài đã thay đổi. Hãy tải lại trước khi thực hiện.',
        );
      }
      final next = switch (action) {
        RecipeVisibilityAction.hide
            when expected.status == RecipeSubmissionStatus.approved =>
          'hidden',
        RecipeVisibilityAction.restore
            when expected.status == RecipeSubmissionStatus.hidden &&
                data['visibilityRole'] == 'author' =>
          'approved',
        RecipeVisibilityAction.delete
            when expected.status != RecipeSubmissionStatus.deleted =>
          'deleted',
        _ => throw const RecipeAuthoringException(
          'Không thể thực hiện thao tác này. Bài do admin ẩn chỉ admin mới được hiện lại.',
        ),
      };
      tx.update(ref, {
        'status': next,
        'isBanner': false,
        'visibilityEventId': event.id,
        'visibilityActor': store.uid,
        'visibilityRole': 'author',
        'visibilityReason': null,
        'visibilityAt': FieldValue.serverTimestamp(),
      });
      tx.set(event, {
        'actor': store.uid,
        'role': 'author',
        'reason': null,
        'fromStatus': data['status'],
        'toStatus': next,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    store.checkSession();
  }

  @override
  Future<void> createRevision(String id) async {
    store.checkSession();
    final reference = store.firestore.collection('recipes').doc(id);
    final snapshot = await reference.get();
    final source = snapshot.data();
    if (source == null ||
        source['authorId'] != store.uid ||
        source['status'] != 'rejected') {
      throw const RecipeAuthoringException(
        'Chỉ có thể sửa và gửi lại bài đã bị từ chối.',
      );
    }
    final content = RecipeContent.fromJson(
      source['content'] as Map<String, dynamic>,
      await catalog.fetchCatalog(),
    );
    var draft = RecipeDraft.fromContent(content);
    if (source['remix'] != null) {
      final remix = RecipeRemix.fromJson(
        Map<String, dynamic>.from(source['remix'] as Map),
      );
      // Giữ nguồn và yêu cầu sửa nội dung bị từ chối trước khi gửi một phiên bản mới.
      draft = draft.copyWith(
        remix: remix,
        remixBaseline: draft.contentFingerprint,
      );
    }
    final encoded = RecipeDraftCodec.encode(draft);
    final slot = store.account.collection('recipe_drafts').doc('current');
    final proposed = 'r_${store.firestore.collection('recipes').doc().id}';
    final created = await store.firestore.runTransaction((tx) async {
      final current = await tx.get(slot);
      if (current.data()?['draft'] != null) return false;
      tx.set(slot, {
        'schemaVersion': 1,
        'authorId': store.uid,
        'submissionId': proposed,
        'revision': 0,
        'draft': encoded,
        'revisionOf': id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    store.checkSession();
    if (!created) {
      throw const RecipeAuthoringException(
        'Bạn đang có bản nháp. Hãy hoàn tất bản nháp trước khi sửa bài khác.',
      );
    }
  }

  @override
  Future<List<RecipeSubmission>> fetchOwn() async {
    store.checkSession();
    final snapshot = await store.firestore
        .collection('recipes')
        .where('authorId', isEqualTo: store.uid)
        .where('status', whereIn: ['pending', 'approved', 'rejected', 'hidden'])
        .orderBy('submittedAt', descending: true)
        .limit(50)
        .get();
    store.checkSession();
    return snapshot.docs
        .where((doc) => doc.data()['status'] != 'deleted')
        .map(
          (doc) => RecipeSubmission.fromJson(doc.id, {
            ...doc.data(),
            'submittedAt': (doc.data()['submittedAt'] as Timestamp).toDate(),
          }),
        )
        .toList();
  }
}
