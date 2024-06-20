import 'dart:convert';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_service.dart';
import 'package:evercrypted/core/entities/contact/contact_riverpod.dart';
import 'package:evercrypted/core/entities/message/message_isar.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/services/app_state.dart';
import 'package:evercrypted/core/socket/event_types/auth_event_types.dart';
import 'package:evercrypted/core/socket/event_types/chat_event_types.dart';
import 'package:evercrypted/core/socket/event_types/contact_event_types.dart';
import 'package:evercrypted/core/entities/contact/contact_service.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/socket/event_types/error_event_types.dart';
import 'package:evercrypted/core/socket/event_types/message_event_types.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:isar/isar.dart';

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
    print('Channel: $channel');
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
      default:
        print('Unknown Event');
        print(payload);
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
        print('Unknown Contact Event');
        print(payload);
    }
  }

  handleErrorEvent(String type, dynamic payload) {
    if (type == ErrorEventTypes.accessDenied) {
    } else if (type == ErrorEventTypes.noOTPToken ||
        type == ErrorEventTypes.invalidOTPToken) {
      Auth.setIsOtpActive(isOtpActive: true, skipNotify: true);
      Auth.clearOtpToken();
    } else if (type == ErrorEventTypes.userLoggedInElsewhere) {
    } else if (type == ErrorEventTypes.couldNotLogin) {
    } else {
      print('Unknown Error Event');
      print(payload);
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
        chatService.syncChats((payload['chats'] as List<dynamic>)
            .map((chatData) => Chat.fromJson(chatData))
            .toList());
        messageService.syncMessages((payload['unreadMessages'] as List<dynamic>)
            .map((messageData) => Message.fromJson(messageData))
            .toList());
        Future.delayed(
            const Duration(seconds: 2), () => chatService.updateChatLastSeen());
        break;
      default:
        print('Unknown General Event');
        print(payload);
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
        print('Unknown Contact Request Event');
        print(payload);
    }
  }

  handleContactEvent(String type, dynamic payload) {
    switch (type) {
      case ContactEventTypes.contactDeleted:
        final isar = Isar.getInstance();
        List<Contact> contacts = isar!.contacts.where().findAllSync();
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
      default:
        print('Unknown Contact Event');
        print(payload);
    }
  }

  handleChatEvent(String type, dynamic payload) {
    final userId = Auth.user?.uid;
    switch (type) {
      case ChatEventTypes.chatCreated:
        Chat chat = Chat.fromJson(payload['chat']);
        chatService.syncChats([chat]);
        String creatorEmail = chat.participants
            .firstWhere((element) => element.uid != userId)
            .email!;
        LocalNotification.instance.displayNotification(
          'Contact',
          'Your contact $creatorEmail has created a chat with you',
          json.encode({
            'type': null,
          }),
        );
        break;
      case ChatEventTypes.chatDeleted:
        final isar = Isar.getInstance();
        final List<Chat> chats = isar!.chats.where().findAllSync();
        final Chat chat =
            chats.firstWhere((element) => element.uid == payload['chatUid']);
        chatService.deleteChat(chatUid: payload['chatUid']);
        LocalNotification.instance.displayNotification(
          'Chat Deleted',
          chat.name != null
              ? 'Chat ${chat.name} has been deleted'
              : 'Chat with ${chat.participants.firstWhere((element) => element.uid != userId).email} has been deleted',
          json.encode({
            'type': null,
          }),
        );
        break;
      default:
        print('Unknown Contact Event');
        print(payload);
    }
  }

  handleMessageEvent(String type, dynamic payload) async {
    switch (type) {
      case MessageEventTypes.messageReceived:
        Message message = Message.fromJson(payload['message']);
        await messageService.writeNewMessageToIsar(message);

        final isar = Isar.getInstance();
        List<Chat> chats = isar!.chats.where().findAllSync();
        Chat? chat =
            chats.firstWhereOrNull((element) => element.uid == message.chatUid);

        if (chat != null && AppState.openedChatId != message.chatUid) {
          String chatname;
          if (chat.name != null && chat.name!.isNotEmpty) {
            chatname = chat.name!;
          } else {
            final userId = Auth.user?.uid;
            chatname = chat.participants
                    .firstWhere((element) => element.uid != userId)
                    .email ??
                '';
          }
          LocalNotification.instance.displayNotification(
            'Message',
            'New message from $chatname',
            json.encode({
              'type': NotificationEventTypes.goToChatPage,
            }),
          );
          chatService.updateChatLastSeen(chatUid: chat.uid);
        }
        break;
      default:
        print('Unknown Contact Event');
        print(payload);
    }
  }
}
