import 'package:evercrypted/core/entities/contact-request/contact_request_riverpod.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//--riverpods
class ProfileRiverpod {
  ProfileRiverpod(this.ref);

  final Ref ref;

  late Profile? profile;

  // final ProfileService _profileService = ProfileService();

  setProfileWhenSignIn(data, {justVerified = false}) {
    profile = Profile(
        fbUid: data.uid,
        name: data.displayName,
        email: data.email,
        emailVerified: data.emailVerified);
    // _profileService.setProfile(profile!);
  }
}

//--providers
final profileProvider =
    Provider<ProfileRiverpod>((ref) => ProfileRiverpod(ref));
