import 'dart:async';
import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';

import '../../chat_socket.dart';
import 'contact_request_event_types.dart';

class ContactRequestService {
  Future<dynamic> createContactRequest(ContactRequest cRequest) {
    return ChatSocket.instance.emitWAck('contactRequest',
        ContactRequestEvents.createContactRequest.name, cRequest.toJson());
  }

  Future<dynamic> acceptContactRequest(ContactRequest cRequest) {
    return ChatSocket.instance.emitWAck('contactRequest',
        ContactRequestEvents.acceptContactRequest.name, cRequest.uid);
  }

  Future<dynamic> cancelContactReqeuest(ContactRequest cRequest) {
    return ChatSocket.instance.emitWAck('contactRequest',
        ContactRequestEvents.cancelContactRequest.name, cRequest.uid);
  }

  Future<dynamic> declineContactRequest(ContactRequest cRequest) {
    return ChatSocket.instance.emitWAck('contactRequest',
        ContactRequestEvents.declineContactRequest.name, cRequest.uid);
  }
}
