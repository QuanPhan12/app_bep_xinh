import 'package:equatable/equatable.dart';

import '../../../core/services/json_reader.dart';

enum UserRole {
  user,
  moderator,
  admin;

  static UserRole parse(Object? value) => switch (value) {
    'user' => user,
    'moderator' => moderator,
    'admin' => admin,
    _ => throw const FormatException('Invalid user role'),
  };
}

enum UserStatus {
  active,
  locked;

  static UserStatus parse(Object? value) => switch (value) {
    'active' => active,
    'locked' => locked,
    _ => throw const FormatException('Invalid user status'),
  };
}

/// Hồ sơ bất biến; UID là khóa document. Quyền quản trị không được cấp từ dữ liệu client.
class UserProfile extends Equatable {
  static const currentSchemaVersion = 1;
  final int schemaVersion;
  final String id;
  final String name;
  final String handle;
  final String bio;
  final int cookedCount;
  final bool showBio;
  final String? avatarUrl;
  // Chỉ phục vụ dữ liệu mẫu; không ghi đường dẫn asset của thiết bị lên Firestore.
  final String? avatarAsset;
  final UserRole role;
  final UserStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final DateTime? lockedAt;
  final String? lockReason;

  bool get isLocked => status == UserStatus.locked;

  const UserProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.bio,
    required this.cookedCount,
    required this.showBio,
    this.schemaVersion = 0,
    this.avatarUrl,
    this.avatarAsset,
    this.role = UserRole.user,
    this.status = UserStatus.active,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.lockedAt,
    this.lockReason,
  });

  /// JSON dùng ISO-8601 hoặc DateTime; Timestamp của Firebase được chuyển ở codec tầng service.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final version = json['schemaVersion'] == null
        ? 0
        : reader.integer('schemaVersion');
    if (version > currentSchemaVersion) {
      throw const FormatException('Unsupported user schema');
    }
    final id = reader.string('id');
    final name = reader.string('name');
    final handle = reader.string('handle');
    final bio = reader.string('bio', allowEmpty: true);
    if (id.length > 128 ||
        id.contains('/') ||
        id.trim() != id ||
        name.trim().isEmpty ||
        name.length > 60 ||
        name.trim() != name ||
        handle.length > 132 ||
        handle.trim() != handle ||
        bio.length > 200 ||
        RegExp(r'[\x00-\x1F\x7F]').hasMatch('$id$name$handle')) {
      throw const FormatException('Invalid user profile fields');
    }
    final role = UserRole.parse(json['role'] ?? (version == 0 ? 'user' : null));
    final status = UserStatus.parse(
      json['status'] ?? (version == 0 ? 'active' : null),
    );
    final createdAt = _date(json['createdAt']);
    final updatedAt = _date(json['updatedAt']);
    final lastLoginAt = _date(json['lastLoginAt']);
    final lockedAt = _date(json['lockedAt']);
    final lockReason = reader.optionalString('lockReason');
    if ((version == 1 && (createdAt == null || updatedAt == null)) ||
        (createdAt != null &&
            updatedAt != null &&
            updatedAt.isBefore(createdAt)) ||
        (lockReason != null && lockReason.length > 500) ||
        (status == UserStatus.locked && lockedAt == null) ||
        (status == UserStatus.active &&
            (lockedAt != null || lockReason != null))) {
      throw const FormatException('Invalid user lifecycle metadata');
    }
    final avatarUrl = reader.optionalString('avatarUrl');
    if (avatarUrl != null) {
      final uri = Uri.tryParse(avatarUrl);
      if (avatarUrl.length > 2048 ||
          uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          uri.hasFragment) {
        throw const FormatException('Invalid user avatar URL');
      }
    }
    return UserProfile(
      id: id,
      name: name,
      handle: handle,
      bio: bio,
      cookedCount: reader.integer('cookedCount'),
      showBio: reader.boolean('showBio', fallback: true),
      schemaVersion: version,
      avatarUrl: avatarUrl,
      avatarAsset: reader.optionalString('avatarAsset'),
      role: role,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
      lockedAt: lockedAt,
      lockReason: lockReason,
    );
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is String && RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toUtc();
    }
    throw const FormatException('Invalid user timestamp');
  }

  // Chỉ cho sửa nội dung hồ sơ; không có copyWith cho role/status hoặc dữ liệu khóa.
  UserProfile copyWith({String? name, String? bio, bool? showBio}) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        handle: handle,
        bio: bio ?? this.bio,
        cookedCount: cookedCount,
        showBio: showBio ?? this.showBio,
        schemaVersion: schemaVersion,
        avatarUrl: avatarUrl,
        avatarAsset: avatarAsset,
        role: role,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
        lastLoginAt: lastLoginAt,
        lockedAt: lockedAt,
        lockReason: lockReason,
      );

  /// Payload whitelist cho phần hồ sơ, không serialize lại toàn bộ document khi lưu.
  Map<String, dynamic> toProfileUpdateJson() => {
    'name': name.trim(),
    'bio': bio.trim(),
    'showBio': showBio,
  };

  /// Export/transport JSON; ghi hồ sơ từ client phải dùng payload whitelist ở trên.
  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'name': name,
    'handle': handle,
    'bio': bio,
    'cookedCount': cookedCount,
    'showBio': showBio,
    'avatarUrl': avatarUrl,
    if (avatarAsset != null) 'avatarAsset': avatarAsset,
    'role': role.name,
    'status': status.name,
    'createdAt': createdAt?.toUtc().toIso8601String(),
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
    'lastLoginAt': lastLoginAt?.toUtc().toIso8601String(),
    'lockedAt': lockedAt?.toUtc().toIso8601String(),
    'lockReason': lockReason,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    handle,
    bio,
    cookedCount,
    showBio,
    schemaVersion,
    avatarUrl,
    avatarAsset,
    role,
    status,
    createdAt,
    updatedAt,
    lastLoginAt,
    lockedAt,
    lockReason,
  ];
}
