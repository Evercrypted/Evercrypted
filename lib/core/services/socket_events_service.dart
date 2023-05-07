import 'package:evercrypted/core/entities/contact/contact_event_types.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';

import '../entities/contact-request/contact_request_event_types.dart';
import '../entities/contact-request/contact_request_model.dart';
import '../entities/contact-request/contact_request_riverpod.dart';
import '../socket/socket_channels.dart';

class SocketEventsService {
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

  handleContactRequestEvent(WidgetRef ref, String type, dynamic payload) {
    switch (type) {
      case ContactRequestEventTypes.contactRequestCreated:
        final contactRequest = ContactRequest.fromJson(payload);
        ref
            .read(receivedRequestsProvider.notifier)
            .addReceivedRequest(contactRequest);
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
