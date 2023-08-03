import 'package:evercrypted/core/notifications/notification_event_types.dart';
import 'package:flutter/material.dart';

import '../../screens/contacts/add_new_contact_screen.dart';
import '../../screens/contacts/contacts_screen.dart';

class NotifiacationEventsService {
  handleNotification(context, payload) {
    switch (payload['type']) {
      case NotificationEventTypes.goToReceivedContactRequestPage:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AddNewContactScreen(
              initialTab: 'received',
            ),
          ),
        );
        break;
      case NotificationEventTypes.goToContactsPage:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ContactsScreen(),
          ),
        );
        break;
      default:
        print('Unknown notification event');
        print(payload);
    }
  }
}
