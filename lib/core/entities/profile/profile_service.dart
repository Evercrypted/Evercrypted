import 'package:evercrypted/main.dart';

import 'profile_model.dart';

class ProfileService {
  void syncProfile(Profile profile) {
    obx.profiles.removeAll();
    obx.profiles.put(profile);
  }

  void updateProfileEmailVerified({required bool emailVerified}) async {
    final profile = obx.profiles.getAll().firstOrNull;
    if (profile != null) {
      profile.emailVerified = emailVerified;
      obx.profiles.put(profile);
    }
  }

  Profile? getProfile() {
    return obx.profiles.getAll().firstOrNull;
  }
}
