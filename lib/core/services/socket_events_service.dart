import 'dart:convert';

import 'package:evercrypted/core/entities/contact-request/contact_request_service.dart';
import 'package:evercrypted/core/socket/event_types/contact_event_types.dart';
import 'package:evercrypted/core/entities/contact/contact_service.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/core/socket/event_types/error_event_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  handleEvent(WidgetRef ref, String channel, String type, dynamic payload) {
    switch (channel) {
      case SocketChannelTypes.contactRequest:
        handleContactRequestEvent(ref, type, payload);
        break;
      case SocketChannelTypes.contact:
        handleContactEvent(ref, type, payload);
        break;
      case SocketChannelTypes.error:
        handleErrorEvent(ref, type, payload);
        break;
      default:
        print('Unknown Event');
        print(payload);
    }
  }

  handleErrorEvent(WidgetRef ref, String type, dynamic payload) {
    if (type == ErrorEventTypes.accessDenied) {
    } else if (type == ErrorEventTypes.noOTPToken ||
        type == ErrorEventTypes.invalidOTPToken) {
    } else if (type == ErrorEventTypes.userLoggedInElsewhere) {
    } else if (type == ErrorEventTypes.couldNotLogin) {
    } else {
      print('Unknown Error Event');
      print(payload);
    }
  }

  handleGeneralEvent(WidgetRef ref, String type, dynamic payload) {
    switch (type) {
      case 'getInitialData':
        contactRequestService
            .syncContactRequests((payload['contactRequests'] as List<dynamic>)
                .map(
                  (contactRequestData) =>
                      ContactRequest.fromJson(contactRequestData),
                )
                .toList());
        profileService.syncProfile(
          Profile.fromJson(payload['profile']),
        );
        break;
      default:
        print('Unknown General Event');
        print(payload);
    }
  }

  handleContactRequestEvent(WidgetRef ref, String type, dynamic payload) {
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

  handleContactEvent(WidgetRef ref, String type, dynamic payload) {
    switch (type) {
      case ContactEventTypes.contactCreated:
        break;
      case ContactEventTypes.contactDeleted:
        break;
      default:
        print('Unknown Contact Event');
        print(payload);
    }
  }
}
