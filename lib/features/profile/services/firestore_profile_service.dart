import '../../recipes/services/published_recipe_source.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/firestore_user_store.dart';
import '../../../core/services/json_reader.dart';
import '../../../core/services/mock_api_client.dart';
import '../../home/models/recipe_item.dart';
import '../../recipes/services/recipe_favorites_service.dart';
import '../models/profile_data.dart';
import 'profile_service.dart';
import '../../recipe_editor/services/recipe_cover_picker.dart';
import '../../recipe_editor/services/recipe_image_uploader.dart';
import '../../recipes/models/recipe_image.dart';

class FirestoreProfileService implements ProfileService, ProfileAvatarService {
  final RecipeCoverPicker avatarPicker;
  final RecipeImageUploader avatarUploader;
  final FirestoreUserStore store;
  final MockApiClient catalog;
  final RecipeFavoritesService favorites;
  final PublishedRecipeSource? published;
  final _changes = StreamController<UserProfile>.broadcast();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  bool _disposed = false;

  FirestoreProfileService({
    required this.store,
    required this.catalog,
    required this.favorites,
    required this.avatarPicker,
    required this.avatarUploader,
    this.published,
  });

  @override
  Stream<UserProfile> get changes => _changes.stream;

  @override
  Future<UserProfile> fetchAccount() async {
    final account = await store.ensureAccount();
    if (_disposed) throw StateError('Profile service disposed');
    _subscription ??= store.account.snapshots().listen(
      (snapshot) {
        if (snapshot.exists &&
            store.auth.currentUser?.uid == store.uid &&
            !_changes.isClosed) {
          try {
            _changes.add(store.readAccount(snapshot.data()!));
          } on FormatException {
            // Không phát hồ sơ sai danh tính vào UI; lần tải tiếp theo sẽ báo lỗi qua Cubit.
          }
        }
      },
      onError: (Object _) {
        // Lỗi listener không xóa dữ liệu đã tải; thao tác tải/lưu vẫn báo lỗi qua Cubit.
      },
    );
    return account;
  }

  @override
  Future<ProfileData> fetchProfile() async {
    final account = await fetchAccount();
    // Gộp bài đã duyệt với nội dung mẫu; không đọc bài chờ duyệt vào hồ sơ công khai.
    final json = await catalog.get('recipe_details');
    final entries = [
      ...await published?.fetchPublished() ?? <Map<String, dynamic>>[],
      ...JsonReader(json).objects('recipes'),
    ];
    final recipes = await Future.wait(
      entries.map(
        (entry) async => RecipeItem.fromRecipeJson(
          entry,
          isFavorite: await favorites.isFavorite(
            JsonReader(entry).string('id'),
            fallback: false,
          ),
        ),
      ),
    );
    store.checkSession();
    return ProfileData(
      account: account,
      recipes: recipes,
      ownRecipeIds: entries
          .where(
            (entry) =>
                entry['author'] is Map &&
                (entry['author'] as Map)['id'] == store.uid,
          )
          .map((entry) => JsonReader(entry).string('id'))
          .toSet(),
    );
  }

  Future<UserProfile> _update(Map<String, dynamic> values) async {
    await fetchAccount();
    store.checkSession();
    await store.account.update({
      ...values,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    store.checkSession();
    final snapshot = await store.account.get();
    store.checkSession();
    final profile = store.readAccount(snapshot.data()!);
    if (!_changes.isClosed) _changes.add(profile);
    return profile;
  }

  @override
  Future<UserProfile> updateProfile({
    required String name,
    required String bio,
  }) {
    if (name.trim().isEmpty ||
        name.trim().length > 60 ||
        bio.trim().length > 200) {
      throw const FormatException('Invalid profile');
    }
    return _update({'name': name.trim(), 'bio': bio.trim()});
  }

  @override
  Future<UserProfile> setShowBio(bool value) => _update({'showBio': value});

  @override
  Future<RecipeImage?> pickAvatar() => avatarPicker.pickCover();

  @override
  Future<UserProfile> updateProfileWithAvatar({
    required String name,
    required String bio,
    required RecipeImage image,
  }) async {
    if (name.trim().isEmpty ||
        name.trim().length > 60 ||
        bio.trim().length > 200) {
      throw const FormatException('Invalid profile');
    }
    store.checkSession();
    final remote = await avatarUploader.upload(image);
    store.checkSession();
    // Lưu tên, giới thiệu và ảnh cùng một lần; upload lỗi không làm mất hồ sơ cũ.
    return _update({
      'name': name.trim(),
      'bio': bio.trim(),
      'avatarUrl': remote.url,
    });
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
    await _changes.close();
  }
}
