import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//--riverpods
class ProfileRiverpod {
  late Profile profile;

  final ProfileService _profileService = ProfileService();

  setProfileWhenSignIn(data) {
    profile = Profile(
        fbUid: data.uid,
        name: data.displayName,
        email: data.email,
        profilePicRef: data.photoURL,
        emailVerified: data.emailVerified);
    _profileService.setProfile(profile);
  }
}

//--providers
final profileProvider = Provider<ProfileRiverpod>((ref) => ProfileRiverpod());
