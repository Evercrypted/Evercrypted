import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/socket/event_types/general_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/main.dart';
import 'package:flutter/widgets.dart';

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
