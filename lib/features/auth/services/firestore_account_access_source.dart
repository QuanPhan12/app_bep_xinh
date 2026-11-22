import 'package:cloud_firestore/cloud_firestore.dart';

import '../../profile/models/user_profile.dart';
import '../../profile/services/user_document_codec.dart';
import '../models/account_access.dart';

class FirestoreAccountAccessSource implements AccountAccessSource {
  final FirebaseFirestore firestore;
  const FirestoreAccountAccessSource(this.firestore);

  @override
  Stream<AccountAccess> watch(String uid) => firestore
      .collection('users')
      .doc(uid)
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) {
        // Cache active có thể là bản trước khi admin khóa. Chỉ server mới được mở phiên.
        if (snapshot.metadata.isFromCache ||
            snapshot.metadata.hasPendingWrites) {
          return const AccountAccess(AccountAccessStatus.checking);
        }
        final data = snapshot.data();
        if (data == null) {
          return const AccountAccess(
            AccountAccessStatus.unavailable,
            message: 'Chưa tìm thấy hồ sơ tài khoản. Vui lòng đăng nhập lại.',
          );
        }
        final profile = UserDocumentCodec.decode(data, documentId: uid);
        return profile.status == UserStatus.locked
            ? AccountAccess(
                AccountAccessStatus.locked,
                message: profile.lockReason,
              )
            : const AccountAccess(AccountAccessStatus.active);
      });
}
