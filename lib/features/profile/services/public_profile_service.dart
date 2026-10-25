import '../models/public_profile_data.dart';

class PublicProfileNotFoundException implements Exception {
  const PublicProfileNotFoundException();
}

abstract interface class PublicProfileService {
  Stream<PublicProfileUser> get publicChanges;
  Future<PublicProfileData> fetchPublicProfile(String userId);
}
