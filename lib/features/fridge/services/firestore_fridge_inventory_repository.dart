import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_user_store.dart';
import 'fridge_inventory_repository.dart';

class FirestoreFridgeInventoryRepository implements FridgeInventoryRepository {
  final FirestoreUserStore store;
  FirestoreFridgeInventoryRepository(this.store);

  DocumentReference<Map<String, dynamic>> get _document =>
      store.account.collection('fridge').doc('current');

  @override
  Future<List<String>> read() async {
    // Home vẫn cho khách xem món, nhưng không cấp tồn kho mẫu của tài khoản khác.
    if (store.uid.isEmpty) return const [];
    store.checkSession();
    final snapshot = await _document.get(
      const GetOptions(source: Source.server),
    );
    store.checkSession();
    final data = snapshot.data();
    if (data == null) return const [];
    if (data['schemaVersion'] != 1 || data['ingredientIds'] is! Map) {
      throw const FormatException('Invalid fridge inventory');
    }
    final selected = data['ingredientIds'] as Map;
    if (selected.length > 500 ||
        selected.values.any((value) => value != true)) {
      throw const FormatException('Invalid fridge inventory');
    }
    return selected.keys.cast<String>().toList();
  }

  @override
  Future<void> save(List<String> ingredientIds) async {
    store.checkSession();
    await _document.set({
      'schemaVersion': 1,
      'ingredientIds': {for (final id in ingredientIds) id: true},
      'updatedAt': FieldValue.serverTimestamp(),
    });
    store.checkSession();
  }
}
