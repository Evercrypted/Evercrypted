import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/socket/event_types/profile_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/core/obx_init.dart';

import 'profile_model.dart';

class ProfileService {
  void syncProfile(Profile profile) {
    // Preserve the existing ObjectBox ID to ensure reactivity
    final existingProfile = ObxInit.obx.profiles.getAll().firstOrNull;
    if (existingProfile != null) {
      profile.id = existingProfile.id;
    }
    ObxInit.obx.profiles.put(profile);
  }

  void updateProfileEmailVerified({required bool emailVerified}) async {
    final profile = ObxInit.obx.profiles.getAll().firstOrNull;
    if (profile != null) {
      profile.emailVerified = emailVerified;
      ObxInit.obx.profiles.put(profile);
    }
  }

  Profile? getProfile() {
    return ObxInit.obx.profiles.getAll().firstOrNull;
  }

  updateProfileSubscription(dynamic payload) {
    if (payload['active'] == true) {
      final profile = getProfile();
      if (profile != null) {
        profile.subscription = ProfileSubscription.fromJson(payload);
        Auth.setAuth(
          profile: profile,
        );
      }
    }
  }

  Future<void> updateAccountSettingsOnServer(
      AccountSettings accountSettings) async {
    try {
      await AppHttpClient.message(
        channel: SocketChannelTypes.general,
        type: 'updateAccountSettings',
        payload: {
          'accountSettings': accountSettings.toJson(),
        },
      );
    } catch (e) {
      // Handle error if needed - could add logging or retry logic
    }
  }

  Future<Profile?> updateProfileOnServer({
    String? name,
    Map<String, dynamic>? avatar,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (avatar != null) payload['avatar'] = avatar;

    final resp = await AppHttpClient.message(
      channel: SocketChannelTypes.profile,
      type: ProfileEventTypes.updateProfile,
      payload: payload,
    );

    if (resp['profile'] != null) {
      final profile = Profile.fromJson(resp['profile']);
      Auth.setAuth(profile: profile);
      return profile;
    }

    return null;
  }
}
