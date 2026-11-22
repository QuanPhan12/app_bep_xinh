import 'package:cloud_firestore/cloud_firestore.dart';

/// Nguồn duy nhất cho nội dung đã duyệt; không đọc collection chờ duyệt vào feed.
class PublishedRecipeSource {
  final FirebaseFirestore firestore;
  PublishedRecipeSource(this.firestore);

  Query<Map<String, dynamic>> get _publishedQuery => firestore
      .collection('recipes')
      .where('status', isEqualTo: 'approved')
      .orderBy('submittedAt', descending: true)
      .limit(100);

  Query<Map<String, dynamic>> get _bannerQuery => firestore
      .collection('recipes')
      .where('status', isEqualTo: 'approved')
      .where('isBanner', isEqualTo: true)
      .orderBy('submittedAt', descending: true)
      .limit(10);

  Stream<List<Map<String, dynamic>>> watchPublished() => _publishedQuery
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_decode).toList());

  Stream<List<Map<String, dynamic>>> watchBanners() => _bannerQuery
      .snapshots()
      .map((snapshot) => snapshot.docs.map(_decode).toList());

  Map<String, dynamic> _decode(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = {
      ...doc.data()!,
      ...Map<String, dynamic>.from(doc.data()!['content'] as Map),
      'isBanner': doc.data()!['isBanner'] == true,
      'id': doc.id,
      'aliases': <String>[],
      'isFavorite': false,
    };
    final date = data['reviewedAt'] ?? data['submittedAt'];
    if (date is Timestamp) {
      data['publishedAt'] = date.toDate().toUtc().toIso8601String();
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> fetchPublished() async {
    final snapshot = await _publishedQuery.get();
    return snapshot.docs.map(_decode).toList();
  }

  Map<String, dynamic> decodeApproved(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    if (doc.data()?['status'] != 'approved') {
      throw const FormatException('Recipe is not approved');
    }
    return _decode(doc);
  }

  Future<Map<String, dynamic>?> find(String id, {bool server = false}) async {
    if (id.contains('/') || id.length > 128) return null;
    final snapshot = await firestore
        .collection('recipes')
        .doc(id)
        .get(server ? const GetOptions(source: Source.server) : null);
    return snapshot.exists && snapshot.data()?['status'] == 'approved'
        ? _decode(snapshot)
        : null;
  }

  Future<List<Map<String, dynamic>>> fetchBanners() async {
    final snapshot = await _bannerQuery.get();
    return snapshot.docs.map(_decode).toList();
  }

  Future<List<Map<String, dynamic>>> forAuthor(String uid) async {
    final snapshot = await firestore
        .collection('recipes')
        .where('status', isEqualTo: 'approved')
        .where('authorId', isEqualTo: uid)
        .orderBy('submittedAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs.map(_decode).toList();
  }
}
