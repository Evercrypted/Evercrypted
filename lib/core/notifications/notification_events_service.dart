import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/notifications/notification_event_types.dart';
import 'package:evercrypted/screens/messages/messages_screen.dart';
import 'package:flutter/material.dart';

import '../../screens/contacts/add_new_contact_screen.dart';

class NotificationEventsService {
  final ChatService chatService = ChatService();
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
      case NotificationEventTypes.goToChatPage:
        final Chat chat = chatService.getChat(chatId: payload['chatId']);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesScreen(chat: chat),
          ),
        );
      case null:
        break;
      default:
    }
  }
}
