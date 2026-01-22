import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/socket/event_types/general_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/core/obx_init.dart';
import 'package:flutter/widgets.dart';

import 'profile_model.dart';

class ProfileService {
  void syncProfile(Profile profile) {
    ObxInit.obx.profiles.removeAll();
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
        type: GeneralEventTypes.updateAccountSettings,
        payload: {
          'accountSettings': accountSettings.toJson(),
        },
      );
    } catch (e) {
      // Handle error if needed - could add logging or retry logic
      debugPrint('Failed to update account settings on server: $e');
    }
  }
}
