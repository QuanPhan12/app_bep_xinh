import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

/// Chỉ tầng service biết kiểu Timestamp; domain giữ DateTime UTC độc lập Firebase.
abstract final class UserDocumentCodec {
  static UserProfile decode(
    Map<String, dynamic> data, {
    required String documentId,
  }) {
    final normalized = Map<String, dynamic>.from(data);
    for (final field in ['createdAt', 'updatedAt', 'lastLoginAt', 'lockedAt']) {
      final value = normalized[field];
      if (value is Timestamp) normalized[field] = value.toDate();
    }
    final profile = UserProfile.fromJson(normalized);
    if (profile.id != documentId) {
      throw const FormatException('User document identity mismatch');
    }
    return profile;
  }
}
