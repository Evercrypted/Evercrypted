import 'package:evercrypted/core/entities/contact-request/contact_request_service.dart';
import 'package:evercrypted/core/entities/contact/contact_event_types.dart';
import 'package:evercrypted/core/entities/profile/profile_service.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';

import '../entities/contact-request/contact_request_event_types.dart';
import '../entities/contact-request/contact_request_model.dart';
import '../entities/contact-request/contact_request_riverpod.dart';
import '../entities/profile/profile_model.dart';
import '../socket/socket_channels.dart';

class SocketEventsService {
  ProfileService profileService = ProfileService();
  ContactRequestService contactRequestService = ContactRequestService();

  handleEvent(WidgetRef ref, String channel, String type, dynamic payload) {
    switch (channel) {
      case SocketChannelTypes.contactRequest:
        handleContactRequestEvent(ref, type, payload);
        break;
      case SocketChannelTypes.contact:
        handleContactEvent(ref, type, payload);
        break;
      default:
        print('Unknown Event');
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
        showSimpleNotification(
            Text(
              'You have got a contact request from ${contactRequest.authorEmail}',
              style: const TextStyle(color: Colors.white),
            ),
            background: secondaryColor);
        break;
      case ContactRequestEventTypes.contactRequestAccepted:
        break;
      case ContactRequestEventTypes.contactRequestCanceled:
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
