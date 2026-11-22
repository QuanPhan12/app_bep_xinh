import 'package:app_bep_xinh/features/profile/models/user_profile.dart';
import 'package:app_bep_xinh/features/profile/services/user_document_codec.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> userJson() => {
  'schemaVersion': 1,
  'id': 'account-a',
  'name': 'Mai Anh',
  'handle': 'bep_account-a',
  'bio': 'Gian bếp nhỏ',
  'showBio': true,
  'cookedCount': 0,
  'role': 'user',
  'status': 'active',
  'avatarUrl': null,
  'createdAt': '2026-11-09T01:00:00Z',
  'updatedAt': '2026-11-09T01:05:00Z',
  'lastLoginAt': null,
  'lockedAt': null,
  'lockReason': null,
};

void main() {
  test('v1 user roundtrips JSON and normalizes timestamps to UTC', () {
    final user = UserProfile.fromJson({
      ...userJson(),
      'lastLoginAt': '2026-11-09T08:05:00+07:00',
    });
    expect(user.status, UserStatus.active);
    expect(user.role, UserRole.user);
    expect(user.lastLoginAt, DateTime.utc(2026, 11, 9, 1, 5));
    expect(UserProfile.fromJson(user.toJson()), user);
  });

  test('locked metadata survives presentation edits and never enters update payload', () {
    final user = UserProfile.fromJson({
      ...userJson(),
      'role': 'moderator',
      'status': 'locked',
      'lockedAt': '2026-11-09T01:05:00Z',
      'lockReason': 'Vi phạm quy định',
    });
    final edited = user.copyWith(
      name: 'Tên mới',
      bio: 'Giới thiệu mới',
      showBio: false,
    );
    expect(edited.isLocked, true);
    expect(edited.role, UserRole.moderator);
    expect(edited.lockedAt, user.lockedAt);
    expect(edited.lockReason, user.lockReason);
    expect(edited.toProfileUpdateJson(), {
      'name': 'Tên mới',
      'bio': 'Giới thiệu mới',
      'showBio': false,
    });
    expect(user, isNot(edited));
  });

  test(
    'legacy profiles read as ordinary active users without invented timestamps',
    () {
      final legacy = userJson()
        ..remove('schemaVersion')
        ..remove('role')
        ..remove('status')
        ..remove('createdAt')
        ..remove('updatedAt');
      final user = UserProfile.fromJson(legacy);
      expect(user.schemaVersion, 0);
      expect(user.role, UserRole.user);
      expect(user.isLocked, false);
      expect(user.createdAt, isNull);
    },
  );

  test('malformed or unknown lifecycle metadata is rejected', () {
    for (final change in <Map<String, dynamic>>[
      {'schemaVersion': 2},
      {'role': 'owner'},
      {'status': 'disabled'},
      {'createdAt': null},
      {'updatedAt': 42},
      {'updatedAt': '2025-01-01T00:00:00Z'},
      {'status': 'locked'},
      {'lockedAt': '2026-11-09T01:05:00Z'},
      {'lockReason': 'unrelated'},
      {'lastLoginAt': '2026-11-09 08:00:00'},
      {'name': 'x' * 61},
      {'bio': 'x' * 201},
      {'id': 'invalid/path'},
      {'name': 'bad\nname'},
    ]) {
      expect(
        () => UserProfile.fromJson({...userJson(), ...change}),
        throwsFormatException,
      );
    }
  });

  test('avatar accepts HTTPS only and rejects credentials/fragments', () {
    expect(
      UserProfile.fromJson({
        ...userJson(),
        'avatarUrl': 'https://images.example.test/avatar.webp',
      }).avatarUrl,
      isNotNull,
    );
    for (final url in [
      'http://example.test/a',
      'file:///a',
      'https://user:pass@example.test/a',
      'https://example.test/a#secret',
    ]) {
      expect(
        () => UserProfile.fromJson({...userJson(), 'avatarUrl': url}),
        throwsFormatException,
      );
    }
  });

  test('Firestore codec converts server timestamps and validates document identity', () {
    final json = {
      ...userJson(),
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 9, 1)),
      'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 11, 9, 1, 5)),
    };
    final user = UserDocumentCodec.decode(json, documentId: 'account-a');
    expect(user.createdAt, DateTime.utc(2026, 11, 9, 1));
    expect(
      () => UserDocumentCodec.decode(json, documentId: 'account-b'),
      throwsFormatException,
    );
    expect(json['createdAt'], isA<Timestamp>());
  });
}
