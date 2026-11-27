import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_user_store.dart';
import '../models/kitchen_entry.dart';

abstract interface class KitchenRepository<T extends KitchenEntry> {
  Stream<List<T>> watch();
  Future<List<T>> fetch();
  Future<T?> find(String id);
  Future<void> createIfAbsent(T value);
  Future<int> count();
  Future<void> save(T value);
  Future<void> update(String id, T Function(T current) change);
  Future<void> delete(String id);
}

class FirestoreKitchenRepository<T extends KitchenEntry>
    implements KitchenRepository<T> {
  final FirestoreUserStore store;
  final String collection;
  final T Function(String, Map<String, dynamic>) decode;
  FirestoreKitchenRepository({
    required this.store,
    required this.collection,
    required this.decode,
  });
  CollectionReference<Map<String, dynamic>> get _items =>
      store.account.collection(collection);
  Query<Map<String, dynamic>> get _query =>
      _items.orderBy('updatedAt', descending: true).limit(500);
  T _read(DocumentSnapshot<Map<String, dynamic>> doc) {
    final value = decode(doc.id, doc.data()!);
    value.toJson();
    return value;
  }

  @override
  Stream<List<T>> watch() {
    store.checkSession();
    return _query
        .snapshots(includeMetadataChanges: true)
        .where((s) => !s.metadata.hasPendingWrites)
        .map((s) {
          store.checkSession();
          return s.docs.map(_read).toList();
        });
  }

  @override
  Future<List<T>> fetch() async {
    store.checkSession();
    final result = await _query.get(const GetOptions(source: Source.server));
    store.checkSession();
    return result.docs.map(_read).toList();
  }

  @override
  Future<int> count() async {
    store.checkSession();
    final result = await _items.count().get();
    store.checkSession();
    return result.count ?? 0;
  }

  @override
  Future<T?> find(String id) async {
    store.checkSession();
    final snapshot = await _items
        .doc(kitchenKey(id))
        .get(const GetOptions(source: Source.server));
    store.checkSession();
    return snapshot.exists ? _read(snapshot) : null;
  }

  Map<String, dynamic> _encode(T value) => kitchenDocumentData(value);
  @override
  Future<void> createIfAbsent(T value) async {
    store.checkSession();
    final ref = _items.doc(kitchenKey(value.id));
    await store.firestore.runTransaction((tx) async {
      final current = await tx.get(ref);
      store.checkSession();
      if (!current.exists) tx.set(ref, _encode(value));
    });
    store.checkSession();
  }

  @override
  Future<void> save(T value) async {
    store.checkSession();
    await _items.doc(kitchenKey(value.id)).set(_encode(value));
    store.checkSession();
  }

  @override
  Future<void> update(String id, T Function(T current) change) async {
    store.checkSession();
    final doc = _items.doc(kitchenKey(id));
    await store.firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      store.checkSession();
      if (!snapshot.exists) throw StateError('Mục đã bị xóa. Hãy tải lại.');
      final next = change(decode(id, snapshot.data()!));
      if (next.id != id) throw StateError('Không thể đổi định danh.');
      transaction.set(doc, _encode(next));
    });
    store.checkSession();
  }

  @override
  Future<void> delete(String id) async {
    store.checkSession();
    await _items.doc(kitchenKey(id)).delete();
    store.checkSession();
  }
}

Map<String, dynamic> kitchenDocumentData(KitchenEntry value) => {
  ...value.toJson(),
  'schemaVersion': value is VersionedKitchenEntry ? value.schemaVersion : 1,
  'updatedAt': FieldValue.serverTimestamp(),
};
