import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/socket/event_types/settings_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/core/obx_init.dart';
import 'package:evercrypted/objectbox.g.dart';
import 'package:flutter/material.dart';

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
      debugPrint('Error reporting content: $e');
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

      debugPrint('BlockService.blockUser response: $response');

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
        debugPrint(
            'BlockService.blockUser blockedUsersData: $blockedUsersData');
        if (blockedUsersData != null) {
          _updateLocalBlockedUsers(blockedUsersData);
        }
        debugPrint('User blocked successfully');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error blocking user: $e');
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

      debugPrint('BlockService.unblockUser response: $response');

      if (response != null) {
        // Update local profile with new blocked users list
        final blockedUsersData = response['blockedUsers'];
        debugPrint(
            'BlockService.unblockUser blockedUsersData: $blockedUsersData');
        if (blockedUsersData != null) {
          _updateLocalBlockedUsers(blockedUsersData);
        }
        debugPrint('User unblocked successfully');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error unblocking user: $e');
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
    debugPrint(
        'BlockService.getBlockedUsers: profile=$profile, blockedUsers=${profile?.blockedUsers}');
    return profile?.blockedUsers ?? [];
  }

  /// Delete local contact by user ID
  static void _deleteLocalContact(String targetUserId) {
    try {
      final query = ObxInit.obx.contacts
          .query(Contact_.contactPersonUid.equals(targetUserId))
          .build();
      final contact = query.findFirst();
      query.close();

      if (contact != null) {
        ObxInit.obx.contacts.remove(contact.id);
        debugPrint(
            'BlockService: Deleted local contact for user $targetUserId');
      }
    } catch (e) {
      debugPrint('Error deleting local contact: $e');
    }
  }

  /// Update local blocked users list from server response
  static void _updateLocalBlockedUsers(List<dynamic> blockedUsersData) {
    try {
      final blockedUsers = blockedUsersData
          .map((e) => BlockedUser.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint(
          'BlockService._updateLocalBlockedUsers: parsed ${blockedUsers.length} blocked users');

      final profile = _profileService.getProfile();
      if (profile != null) {
        final updatedProfile = profile.copyWith(blockedUsers: blockedUsers);
        // Sync to local storage and update in-memory state
        _profileService.syncProfile(updatedProfile);
        // Also update Auth to reflect changes immediately
        Auth.setAuth(profile: updatedProfile);
        debugPrint(
            'BlockService: Updated profile with ${blockedUsers.length} blocked users');
      }
    } catch (e) {
      debugPrint('Error updating local blocked users: $e');
    }
  }
}
