import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileNotifier extends StateNotifier<Profile?> {
  // We initialize the list of todos to an empty list
  ProfileNotifier() : super(null);

  void setProfile(Profile profile) {
    state = profile;
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, Profile?>((ref) {
  return ProfileNotifier();
});
