import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';

import '../entities/contact-request/contact_request_model.dart';
import '../entities/contact-request/contact_request_riverpod.dart';

class SocketEventsService {
  handleEvent(WidgetRef ref, String channel, String type, dynamic payload) {
    switch (channel) {
      case 'contactRequest':
        switch (type) {
          case 'contactRequestCreated':
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
          default:
            print('Unknown Contact Request Event');
            print(payload);
        }
        break;
      default:
        print('Unknown Event');
        print(payload);
    }
  }
}
