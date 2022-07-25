import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileRepository {
  late Profile profile;

  final ProfileService _profileService = ProfileService();

  updateUser(data) {
    profile = Profile(
        userId: data.uid,
        name: data.displayName,
        email: data.email,
        profilePicRef: data.photoURL,
        emailVerified: data.emailVerified);
    checkProfile(data.uid);
  }

  checkProfile(String userId) {
    _profileService.getUserProfile(userId).then((value) {
      if (value == null) {
        _profileService.createUserProfile(profile);
      } else {
        profile = value;
      }
    });
  }
}

final profileProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});
