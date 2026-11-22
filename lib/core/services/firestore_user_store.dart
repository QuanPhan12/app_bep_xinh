import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/profile/models/profile_data.dart';
import '../../features/profile/services/user_document_codec.dart';

/// Mỗi instance chỉ phục vụ một UID; kết quả từ phiên cũ không được đưa vào UI phiên mới.
class FirestoreUserStore {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final String uid;

  FirestoreUserStore({
    required this.firestore,
    required this.auth,
    required this.uid,
  });

  DocumentReference<Map<String, dynamic>> get account =>
      firestore.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> get favorites =>
      account.collection('favorites');

  void checkSession() {
    if (uid.isEmpty || auth.currentUser?.uid != uid) {
      throw StateError('Account session changed');
    }
  }

  UserProfile readAccount(Map<String, dynamic> data) {
    checkSession();
    return UserDocumentCodec.decode(data, documentId: uid);
  }

  Future<UserProfile> ensureAccount() async {
    checkSession();
    final user = auth.currentUser!;
    final data = await firestore.runTransaction<Map<String, dynamic>?>((
      transaction,
    ) async {
      final snapshot = await transaction.get(account);
      if (snapshot.exists) return snapshot.data()!;
      final name = user.displayName?.trim();
      final data = <String, dynamic>{
        'schemaVersion': UserProfile.currentSchemaVersion,
        'id': uid,
        'name':
            name == null ||
                name.isEmpty ||
                name.length > 60 ||
                RegExp(r'[\x00-\x1F\x7F]').hasMatch(name)
            ? 'Người yêu bếp'
            : name,
        // UID đầy đủ tránh hai tài khoản trùng handle do cắt cùng tiền tố.
        'handle': 'bep_$uid',
        'bio': '',
        'showBio': true,
        'cookedCount': 0,
        'avatarUrl': null,
        'role': UserRole.user.name,
        'status': UserStatus.active.name,
        'lastLoginAt': null,
        'lockedAt': null,
        'lockReason': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      transaction.set(account, data);
      return null;
    });
    checkSession();
    // Server timestamp trong payload ghi là sentinel; chỉ parse sau khi server đã xác nhận.
    final resolved =
        data ??
        (await account.get(const GetOptions(source: Source.server))).data();
    checkSession();
    if (resolved == null) {
      throw StateError('User document missing after create');
    }
    return readAccount(resolved);
  }
}
