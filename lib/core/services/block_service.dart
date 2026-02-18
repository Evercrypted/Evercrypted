import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/socket/event_types/settings_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/core/obx_init.dart';
import 'package:evercrypted/objectbox.g.dart';

/// Service for handling user blocking and content reporting
class BlockService {
  BlockService._();

  static final ProfileService _profileService = ProfileService();
  static final ChatService _chatService = ChatService();

  /// Report content (message or user)
  static Future<bool> reportContent({
    required String reportedUserId,
    required String reason,
    String? messageId,
    String? messageContent,
    String? description,
  }) async {
    try {
      final response = await AppHttpClient.message(
        channel: SocketChannelTypes.settings,
        type: SettingsEventTypes.reportContent,
        payload: {
          'reportedUserId': reportedUserId,
          'messageId': messageId,
          'messageContent': messageContent,
          'reason': reason,
          'description': description,
        },
      );

      // Server returns { success: true, message: '...' } on success
      return response is Map && response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Block a user - removes contact and deletes 1-on-1 chats
  static Future<bool> blockUser(String targetUserId) async {
    try {
      final response = await AppHttpClient.message(
        channel: SocketChannelTypes.settings,
        type: SettingsEventTypes.blockUser,
        payload: {
          'targetUserId': targetUserId,
        },
      );

      if (response != null) {
        // Delete local contact with this user
        _deleteLocalContact(targetUserId);

        // Delete local 1-on-1 chat with this user
        await _chatService.findContactChatAndDelete(
          contactUid: targetUserId,
          skipNotify: true, // Server already deleted it
        );

        // Update local profile with new blocked users list
        final blockedUsersData = response['blockedUsers'];

        if (blockedUsersData != null) {
          _updateLocalBlockedUsers(blockedUsersData);
        }

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Unblock a user
  static Future<bool> unblockUser(String targetUserId) async {
    try {
      final response = await AppHttpClient.message(
        channel: SocketChannelTypes.settings,
        type: SettingsEventTypes.unblockUser,
        payload: {
          'targetUserId': targetUserId,
        },
      );

      if (response != null) {
        // Update local profile with new blocked users list
        final blockedUsersData = response['blockedUsers'];

        if (blockedUsersData != null) {
          _updateLocalBlockedUsers(blockedUsersData);
        }

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if a user is blocked locally
  static bool isUserBlocked(String userId) {
    final profile = _profileService.getProfile();
    if (profile?.blockedUsers == null) return false;
    return profile!.blockedUsers!
        .any((blockedUser) => blockedUser.uid == userId);
  }

  /// Get the list of blocked users
  static List<BlockedUser> getBlockedUsers() {
    final profile = _profileService.getProfile();

    return profile?.blockedUsers ?? [];
  }

  /// Delete local contact by user ID
  static void _deleteLocalContact(String targetUserId) {
    final query = ObxInit.obx.contacts
        .query(Contact_.contactPersonUid.equals(targetUserId))
        .build();
    final contact = query.findFirst();
    query.close();

    if (contact != null) {
      ObxInit.obx.contacts.remove(contact.id);
    }
  }

  /// Update local blocked users list from server response
  static void _updateLocalBlockedUsers(List<dynamic> blockedUsersData) {
    final blockedUsers = blockedUsersData
        .map((e) => BlockedUser.fromJson(e as Map<String, dynamic>))
        .toList();

    final profile = _profileService.getProfile();
    if (profile != null) {
      final updatedProfile = profile.copyWith(blockedUsers: blockedUsers);
      // Sync to local storage and update in-memory state
      _profileService.syncProfile(updatedProfile);
      // Also update Auth to reflect changes immediately
      Auth.setAuth(profile: updatedProfile);
    }
  }
}
