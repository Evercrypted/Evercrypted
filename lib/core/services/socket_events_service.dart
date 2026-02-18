import 'dart:convert';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/base_key.dart';
import 'package:evercrypted/core/cryptography/db_encryption.dart';
import 'package:evercrypted/core/cryptography/group_key_exchange.dart';
import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_service.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/services/app_state.dart';
import 'package:evercrypted/core/socket/event_types/auth_event_types.dart';
import 'package:evercrypted/core/socket/event_types/chat_event_types.dart';
import 'package:evercrypted/core/socket/event_types/contact_event_types.dart';
import 'package:evercrypted/core/entities/contact/contact_service.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/socket/event_types/error_event_types.dart';
import 'package:evercrypted/core/socket/event_types/settings_event_types.dart';
import 'package:evercrypted/core/socket/event_types/message_event_types.dart';
import 'package:evercrypted/core/socket/event_types/payment_event_types.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/obx_init.dart';
import 'package:evercrypted/objectbox.g.dart';
import 'package:collection/collection.dart';

import '../entities/chat/chat_model.dart';
import '../entities/chat/chat_service.dart';
import '../socket/event_types/contact_request_event_types.dart';
import '../entities/contact-request/contact_request_model.dart';
import '../entities/contact/contact_model.dart';
import '../entities/profile/profile_model.dart';
import '../notifications/notification.dart';
import '../notifications/notification_event_types.dart';
import '../socket/socket_channels.dart';

class SocketEventsService {
  ProfileService profileService = ProfileService();
  ContactRequestService contactRequestService = ContactRequestService();
  ContactService contactService = ContactService();
  ChatService chatService = ChatService();
  MessageService messageService = MessageService();

  handleEvent(String channel, String type, dynamic payload) {
    switch (channel) {
      case SocketChannelTypes.contactRequest:
        handleContactRequestEvent(type, payload);
        break;
      case SocketChannelTypes.contact:
        handleContactEvent(type, payload);
        break;
      case SocketChannelTypes.error:
        handleErrorEvent(type, payload);
        break;
      case SocketChannelTypes.chat:
        handleChatEvent(type, payload);
        break;
      case SocketChannelTypes.message:
        handleMessageEvent(type, payload);
        break;
      case SocketChannelTypes.auth:
        handleAuthEvent(type, payload);
        break;
      case SocketChannelTypes.payment:
        handlePaymentEvent(type, payload);
        break;
      case SocketChannelTypes.settings:
        handleSettingsEvent(type, payload);
        break;
      default:
        return;
    }
  }

  handlePaymentEvent(String type, dynamic payload) {
    switch (type) {
      case PaymentEventTypes.statusChanged:
        Auth.setAuth(profile: Profile.fromJson(payload['profile']));
        LocalNotification.instance.displayNotification(
            'Profile Status Changed',
            'Your subscription has been updated',
            json.encode({
              'type': null,
            }));
        break;
      default:
        return;
    }
  }

  handleSettingsEvent(String type, dynamic payload) {
    switch (type) {
      case SettingsEventTypes.userBlocked:
        // Someone blocked us - clean up local contact and chat
        final blockerUserId = payload['blockerUserId'] as String?;
        if (blockerUserId != null) {
          // Delete contact with blocker (contactPersonUid is the user's UID)
          final contactQuery = ObxInit.obx.contacts
              .query(Contact_.contactPersonUid.equals(blockerUserId))
              .build();
          final contact = contactQuery.findFirst();
          contactQuery.close();

          if (contact != null) {
            // Directly remove from ObjectBox to trigger stream update
            ObxInit.obx.contacts.remove(contact.id);
          }

          // Delete 1-on-1 chat with blocker
          chatService.findContactChatAndDelete(
            contactUid: blockerUserId,
            skipNotify: true,
          );
        }
        break;
      default:
        return;
    }
  }

  handleAuthEvent(String type, dynamic payload) {
    switch (type) {
      case AuthEventTypes.emailVerified:
        Auth.updateEmailVerified(emailVerified: true);
        Auth.setAuth(newToken: payload['new_token']);
        ChatSocket.resetConnectionSubject.add(true);
        break;
      default:
        return;
    }
  }

  handleErrorEvent(String type, dynamic payload) {
    if (type == ErrorEventTypes.accessDenied) {
      Auth.clearAuth();
    } else if (type == ErrorEventTypes.noOTPToken ||
        type == ErrorEventTypes.invalidOTPToken) {
      Auth.setIsOtpActive(isOtpActive: true, skipNotify: true);
      Auth.clearOtpToken();
    } else if (type == ErrorEventTypes.userLoggedInElsewhere) {
    } else if (type == ErrorEventTypes.couldNotLogin) {
    } else {
      return;
    }
  }

  handleGeneralEvent(String type, dynamic payload) async {
    switch (type) {
      case 'getInitialData':
        await Auth.setAuth(
            newIsOtpActive: payload['profile']['isOtpActive'],
            profile: Profile.fromJson(payload['profile']),
            newToken: payload['newToken']);
        contactRequestService
            .syncContactRequests((payload['contactRequests'] as List<dynamic>)
                .map(
                  (contactRequestData) =>
                      ContactRequest.fromJson(contactRequestData),
                )
                .toList());
        contactService.syncContacts((payload['contacts'] as List<dynamic>)
            .map((contactData) => Contact.fromJson(contactData))
            .toList());
        chatService.updateChatLastSeen();
        chatService.syncChats((payload['chats'] as List<dynamic>)
            .map((chatData) => Chat.fromJson(chatData))
            .toList());
        // messageService.syncMessages((payload['unreadMessages'] as List<dynamic>)
        //     .map((messageData) => Message.fromJson(messageData))
        //     .toList());
        break;
      default:
        return;
    }
  }

  handleContactRequestEvent(String type, dynamic payload) {
    switch (type) {
      case ContactRequestEventTypes.contactRequestCreated:
        final contactRequest = ContactRequest.fromJson(payload);
        contactRequestService.syncContactRequests([contactRequest]);
        LocalNotification.instance.displayNotification(
            'Contact Request',
            'You have got a contact request from ${contactRequest.authorEmail}',
            json.encode({
              'type': NotificationEventTypes.goToReceivedContactRequestPage,
            }));
        break;
      case ContactRequestEventTypes.contactRequestAccepted:
        final contact = Contact.fromJson(payload['contact']);
        contactService.createContactAndRemoveContactRequest(
            contact, payload['contactRequestUid']);
        LocalNotification.instance.displayNotification(
          'Contact Request',
          'Your contact request was accepted by ${contact.email}',
          json.encode({
            'type': NotificationEventTypes.goToContactsPage,
          }),
        );
        break;
      case ContactRequestEventTypes.contactRequestCanceled:
        contactRequestService
            .deleteContactRequest(payload['contactRequestUid']);
        LocalNotification.instance.displayNotification(
          'Contact Request',
          'A contact request was canceled by ${payload['authorEmail']}',
          json.encode({
            'type': NotificationEventTypes.goToReceivedContactRequestPage,
          }),
        );
        break;
      default:
        return;
    }
  }

  handleContactEvent(String type, dynamic payload) {
    switch (type) {
      case ContactEventTypes.contactDeleted:
        List<Contact> contacts = ObxInit.obx.contacts.getAll();
        String? contactEmail = contacts
            .firstWhere(
              (element) => element.uid == payload['contactUid'],
            )
            .email;
        contactService.handleDeletedContact(payload['contactUid']);
        chatService
            .findContactChatAndDelete(
                contactUid: payload['contactUid'], skipNotify: true)
            .then((bool chatWasFound) {
          if (chatWasFound) {
            LocalNotification.instance.displayNotification(
              'Contact',
              'Your contact $contactEmail has deleted chat with you and removed you from their contacts',
              json.encode({
                'type': null,
              }),
            );
          } else {
            LocalNotification.instance.displayNotification(
              'Contact',
              'Your contact $contactEmail has removed you from their contacts',
              json.encode({
                'type': null,
              }),
            );
          }
        });
        break;
      case ContactEventTypes.contactUpdated:
        final updatedContact = Contact.fromJson(payload['contact']);
        final existingContact = contactService.findContactByUid(updatedContact.uid!);
        if (existingContact != null) {
          // Update the existing contact with new data from server
          // Note: We preserve customName - only update the actual profile data
          existingContact.name = updatedContact.name;
          existingContact.email = updatedContact.email;
          existingContact.avatar = updatedContact.avatar;
          // customName is NOT updated - it's a local preference
          ObxInit.obx.contacts.put(existingContact);

          // Also update participant info in all chats with this contact
          final chats = ObxInit.obx.chats.getAll();
          for (final chat in chats) {
            bool updated = false;
            final updatedParticipants = chat.participants.map((p) {
              if (p.uid == updatedContact.contactPersonUid) {
                updated = true;
                return p.copyWith(
                  name: updatedContact.name,
                  email: updatedContact.email,
                  avatar: updatedContact.avatar,
                );
              }
              return p;
            }).toList();

            if (updated) {
              chat.participants = updatedParticipants;
              // For 1:1 chats, the chat avatar IS the other participant's avatar
              if (chat.isOneToOne) {
                chat.avatar = updatedContact.avatar;
              }
              ObxInit.obx.chats.put(chat);
            }
          }
        }
        break;
      default:
        return;
    }
  }

  handleChatEvent(String type, dynamic payload) async {
    final userId = Auth.user?.uid;
    switch (type) {
      case ChatEventTypes.chatCreated:
        Chat chat = Chat.fromJson(payload['chat']);
        chatService.addChat(chat, isNewlyCreated: false);
        String creatorEmail = chat.participants
            .firstWhere((element) => element.uid != userId)
            .email!;
        LocalNotification.instance.displayNotification(
          'Contact',
          'Your contact $creatorEmail has created a chat with you',
          json.encode({
            'type': NotificationEventTypes.goToChatPage,
            'chatId': chat.id,
          }),
        );
        break;
      case ChatEventTypes.chatDeleted:
        final query = ObxInit.obx.chats
            .query(Chat_.uid.equals(payload['chatUid']))
            .build();
        final Chat? chat = query.findFirst();
        query.close();
        if (chat != null) {
          chatService.deleteChat(chatUid: payload['chatUid'], skipNotify: true);
          LocalNotification.instance.displayNotification(
            'Chat Deleted',
            chat.name != null
                ? 'Chat ${chat.name} has been deleted'
                : 'Chat with ${chat.participants.firstWhere((element) => element.uid != userId).email} has been deleted',
            json.encode({
              'type': null,
            }),
          );
        }
        break;
      case ChatEventTypes.participantsAdded:
        final Chat chat = Chat.fromJson(payload['chat']);
        final List<String> newParticipantUids =
            payload['newParticipantUids'].cast<String>();
        final List<Participant> newParticipants = chat.participants
            .where((element) => newParticipantUids.contains(element.uid))
            .toList();
        await chatService.updateChatFromResp(chat);
        messageService
            .writeNewMessageToObx(Message.fromJson(payload['sysMessage']));
        LocalNotification.instance.displayNotification(
          'Participant Added',
          '${newParticipants.length > 1 ? 'Participants' : 'Participant'} ${newParticipants.map(
                (e) => e.name ?? e.email,
              ).join(', ')} has been added to chat - ${chat.name}',
          json.encode({
            'type': null,
          }),
        );
        break;
      case ChatEventTypes.joinedViaInvite:
        final chat = Chat.fromJson(payload['chat']);
        chatService.addChat(chat, isNewlyCreated: false);

        // Ensure group key is present (important if I am the joiner)
        if (!chat.isOneToOne) {
          await GroupKeyExchange.ensureGroupKey(chat.uid, chat.isOneToOne);
        }

        final sysMessage = Message.fromJson(payload['sysMessage']);
        messageService.writeNewMessageToObx(sysMessage);

        LocalNotification.instance.displayNotification(
          'Group Chat Update',
          'New participant joined via invite link',
          json.encode({
            'type': NotificationEventTypes.goToChatPage,
            'chatId': chat.id,
          }),
        );
        break;
      case ChatEventTypes.addedToChat:
        final chat = Chat.fromJson(payload['chat']);
        chatService.addChat(chat,
            isNewlyCreated: false); // This is an existing group

        // If I was added to a group chat, automatically request group key
        if (!chat.isOneToOne) {
          await GroupKeyExchange.ensureGroupKey(chat.uid, chat.isOneToOne);
        }
        messageService
            .writeNewMessageToObx(Message.fromJson(payload['sysMessage']));
        LocalNotification.instance.displayNotification(
          'Added to Chat',
          'You have been added to chat - ${chat.name}',
          json.encode({
            'type': NotificationEventTypes.goToChatPage,
          }),
        );
        break;
      case ChatEventTypes.participantRemoved:
        final chat = Chat.fromJson(payload['chat']);
        final participantName = payload['participantName'];
        await chatService.updateChatFromResp(chat);
        messageService
            .writeNewMessageToObx(Message.fromJson(payload['sysMessage']));
        LocalNotification.instance.displayNotification(
          'Participant Removed',
          'Participant $participantName has been removed from chat - ${chat.name}',
          json.encode({
            'type': null,
          }),
        );
        break;
      case ChatEventTypes.removedFromChat:
        final String chatName = payload['chatName'];
        chatService.deleteChat(chatUid: payload['chatUid'], skipNotify: true);
        LocalNotification.instance.displayNotification(
          'Removed from Chat',
          'You have been removed from chat - $chatName',
          json.encode({
            'type': null,
          }),
        );
        break;
      case ChatEventTypes.leftChat:
        final Chat chat = Chat.fromJson(payload['chat']);
        await chatService.updateChatFromResp(chat);
        messageService
            .writeNewMessageToObx(Message.fromJson(payload['sysMessage']));
        final String userEmail = payload['userEmail'];
        LocalNotification.instance.displayNotification(
          'Left Chat',
          '$userEmail has left chat - ${chat.name}',
          json.encode({
            'type': null,
          }),
        );
        break;
      case ChatEventTypes.chatUpdated:
        final Chat chat = Chat.fromJson(payload['chat']);
        chatService.updateChatFromResp(chat);
        break;
      case ChatEventTypes.keyExchange:
        final String chatUid = payload['chatUid'];
        final String ciphertext = payload['ciphertext'];
        await _handleKeyExchange(chatUid, ciphertext);
        break;
      default:
        return;
    }
  }

  handleMessageEvent(String type, dynamic payload) async {
    switch (type) {
      case MessageEventTypes.messageReceived:
        Message message = Message.fromJson(payload['message']);

        // Process group key exchange messages in background (don't store in DB)
        if (message.messageType == MessageTypes.requestForAGroupKey ||
            message.messageType == MessageTypes.responseForAGroupKey) {
          await MessageProcessor.processMessage(message);
          return; // Don't store these protocol messages in DB or show in UI
        }

        // Store regular messages in DB
        await messageService.writeNewMessageToObx(message);

        List<Chat> chats = ObxInit.obx.chats.getAll();
        Chat? chat =
            chats.firstWhereOrNull((element) => element.uid == message.chatUid);

        if (chat != null) {
          chatService.updateChatLastSeen(chatUid: chat.uid);
          if (AppState.openedChatId != message.chatUid) {
            String? chatname;
            if (chat.name != null && chat.name!.isNotEmpty) {
              chatname = chat.name!;
            } else {
              final String appKey = await Auth.getAppKey;
              final userId = Auth.user?.uid;
              final otherParticipant = chat.participants
                  .firstWhere((element) => element.uid != userId);
              chatname = otherParticipant.name != null
                  ? decryptForDb(otherParticipant.name, appKey)
                  : decryptForDb(otherParticipant.email, appKey);
            }
            LocalNotification.instance.displayNotification(
              'Message',
              'New message from $chatname',
              json.encode({
                'type': NotificationEventTypes.goToChatPage,
                'chatId': chat.id,
              }),
            );
          }
        }
        break;
      default:
        return;
    }
  }

  Future<void> _handleKeyExchange(String chatUid, String ciphertext) async {
    // Store the encapsulated data and trigger key decapsulation
    await BaseKey.setKeys(
      chatUid: chatUid,
      ciphertext: ciphertext,
    );

    // Trigger the _checkKeys logic to decapsulate the secret
    final chat = chatService.getChat(chatUid: chatUid);
    if (chat != null) {
      await chatService.checkKeys(chat);
    }
  }
}
