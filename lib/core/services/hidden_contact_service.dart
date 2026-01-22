import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/obx_init.dart';

class HiddenContactService {
  final ProfileService _profileService = ProfileService();

  // Hide a contact with a password
  void hideContact(String contactUid, String password) {
    final profile = _profileService.getProfile();
    if (profile == null) return;

    // Initialize hiddenContacts if null
    final hiddenContacts = profile.accountSettings?.hiddenContacts ?? {};

    // Add the contact with its password
    hiddenContacts[contactUid] = password;

    // Update the profile with new settings
    final updatedAccountSettings = AccountSettings(
      appIcon: profile.accountSettings?.appIcon,
      hiddenChats: profile.accountSettings?.hiddenChats,
      hiddenContacts: hiddenContacts,
    );

    profile.accountSettings = updatedAccountSettings;

    // Save to database
    ObxInit.obx.profiles.put(profile);

    // Sync to server
    _profileService.updateAccountSettingsOnServer(updatedAccountSettings);
  }

  // Unhide a contact
  void unhideContact(String contactUid) {
    final profile = _profileService.getProfile();
    if (profile == null) return;

    final hiddenContacts = profile.accountSettings?.hiddenContacts ?? {};

    // Remove the contact from hidden contacts
    hiddenContacts.remove(contactUid);

    // Update the profile
    final updatedAccountSettings = AccountSettings(
      appIcon: profile.accountSettings?.appIcon,
      hiddenChats: profile.accountSettings?.hiddenChats,
      hiddenContacts: hiddenContacts,
    );

    profile.accountSettings = updatedAccountSettings;

    // Save to database
    ObxInit.obx.profiles.put(profile);

    // Sync to server
    _profileService.updateAccountSettingsOnServer(updatedAccountSettings);
  }

  // Check if a contact is hidden
  bool isContactHidden(String contactUid, Profile? profile) {
    if (profile == null) return false;

    final hiddenContacts = profile.accountSettings?.hiddenContacts ?? {};
    return hiddenContacts.containsKey(contactUid);
  }

  // Get all hidden contact UIDs
  Set<String> getHiddenContactUids(Profile? profile) {
    if (profile == null) return {};

    final hiddenContacts = profile.accountSettings?.hiddenContacts ?? {};
    return hiddenContacts.keys.toSet();
  }

  // Check if password matches any hidden contact
  Set<String> getContactsMatchingPassword(String password, Profile? profile) {
    if (profile == null) return {};

    final hiddenContacts = profile.accountSettings?.hiddenContacts ?? {};
    final matchingContacts = <String>{};

    hiddenContacts.forEach((contactUid, contactPassword) {
      if (contactPassword == password) {
        matchingContacts.add(contactUid);
      }
    });

    return matchingContacts;
  }

  // Get password for a hidden contact (for validation)
  String? getHiddenContactPassword(String contactUid, Profile? profile) {
    if (profile == null) return null;

    final hiddenContacts = profile.accountSettings?.hiddenContacts ?? {};
    return hiddenContacts[contactUid];
  }
}
