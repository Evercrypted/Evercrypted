import 'package:evercrypted/core/notifications/notification_event_types.dart';
import 'package:flutter/material.dart';

import '../../screens/contacts/add_new_contact_screen.dart';

class NotifiacationEventsService {
  handleNotification(context, payload) {
    switch (payload['type']) {
      case NotificationEventTypes.goToReceivedContactRequestPage:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddNewContactScreen(
              initialTab: 'received',
            ),
          ),
        );
        break;
      case NotificationEventTypes.goToContactsPage:
        Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
        break;
      case null:
        break;
      default:
        print('Unknown notification event');
        print(payload);
    }
  }
}
