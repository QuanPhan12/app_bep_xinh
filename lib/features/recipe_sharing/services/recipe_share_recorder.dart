import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_user_store.dart';
import '../../kitchen/models/kitchen_entry.dart';

class RecipeShareRecorder {
  const RecipeShareRecorder(this.store);
  final FirestoreUserStore store;

  Future<void> record(String recipeId, String channel) async {
    // Khách vẫn chia sẻ được; chỉ ghi nhận tài khoản thật và công thức trên server.
    if (store.uid.isEmpty || !recipeId.startsWith('r_')) return;
    store.checkSession();
    final receipt = store.firestore
        .collection('recipes')
        .doc(kitchenKey(recipeId))
        .collection('shares')
        .doc(store.uid);
    await store.firestore.runTransaction((transaction) async {
      final previous = await transaction.get(receipt);
      store.checkSession();
      if (previous.exists) return;
      transaction.set(receipt, {
        'uid': store.uid,
        'channel': channel,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(receipt.parent.parent!, {
        'engagement': {
          'shareCount': FieldValue.increment(1),
          'likeCount': FieldValue.increment(0),
        },
      }, SetOptions(merge: true));
    });
  }
}
