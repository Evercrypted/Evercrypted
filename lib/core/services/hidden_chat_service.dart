import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/main.dart';

class HiddenChatService {
  final ProfileService _profileService = ProfileService();

  // Hide a chat with a password
  void hideChat(String chatUid, String password) {
    final profile = _profileService.getProfile();
    if (profile == null) return;

    // Initialize hiddenChats if null
    final hiddenChats = profile.accountSettings?.hiddenChats ?? {};

    // Add the chat with its password
    hiddenChats[chatUid] = password;

    // Update the profile with new settings
    final updatedAccountSettings = AccountSettings(
      appIcon: profile.accountSettings?.appIcon,
      hiddenChats: hiddenChats,
      hiddenContacts: profile.accountSettings?.hiddenContacts,
    );

    profile.accountSettings = updatedAccountSettings;

    // Save to database
    obx.profiles.put(profile);

    // Sync to server
    _profileService.updateAccountSettingsOnServer(updatedAccountSettings);
  }

  // Unhide a chat
  void unhideChat(String chatUid) {
    final profile = _profileService.getProfile();
    if (profile == null) return;

    final hiddenChats = profile.accountSettings?.hiddenChats ?? {};

    // Remove the chat from hidden chats
    hiddenChats.remove(chatUid);

    // Update the profile
    final updatedAccountSettings = AccountSettings(
      appIcon: profile.accountSettings?.appIcon,
      hiddenChats: hiddenChats,
      hiddenContacts: profile.accountSettings?.hiddenContacts,
    );

    profile.accountSettings = updatedAccountSettings;

    // Save to database
    obx.profiles.put(profile);

    // Sync to server
    _profileService.updateAccountSettingsOnServer(updatedAccountSettings);
  }

  // Check if a chat is hidden
  bool isChatHidden(String chatUid, Profile? profile) {
    if (profile == null) return false;

    final hiddenChats = profile.accountSettings?.hiddenChats ?? {};
    return hiddenChats.containsKey(chatUid);
  }

  // Get all hidden chat UIDs
  Set<String> getHiddenChatUids(Profile? profile) {
    if (profile == null) return {};

    final hiddenChats = profile.accountSettings?.hiddenChats ?? {};
    return hiddenChats.keys.toSet();
  }

  // Check if password matches any hidden chat
  Set<String> getChatsMatchingPassword(String password, Profile? profile) {
    if (profile == null) return {};

    final hiddenChats = profile.accountSettings?.hiddenChats ?? {};
    final matchingChats = <String>{};

    hiddenChats.forEach((chatUid, chatPassword) {
      if (chatPassword == password) {
        matchingChats.add(chatUid);
      }
    });

    return matchingChats;
  }

  // Get password for a hidden chat (for validation)
  String? getHiddenChatPassword(String chatUid, Profile? profile) {
    if (profile == null) return null;

    final hiddenChats = profile.accountSettings?.hiddenChats ?? {};
    return hiddenChats[chatUid];
  }
}
