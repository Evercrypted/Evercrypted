import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//--riverpods
class ProfileRiverpod {
  ProfileRiverpod(this.ref);

  final Ref ref;

  late Profile? profile;

  // final ProfileService _profileService = ProfileService();

  setProfileWhenSignIn(data) {
    profile = Profile(
      uid: data.uid,
      name: data.name,
      email: data.email,
      avatar: Avatar.fromJson(data.avatar),
    );
  }
}

//--providers
final profileProvider =
    Provider<ProfileRiverpod>((ref) => ProfileRiverpod(ref));
