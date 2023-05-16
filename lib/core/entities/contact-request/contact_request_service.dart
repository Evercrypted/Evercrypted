import 'dart:async';
import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:isar/isar.dart';

import '../../socket/chat_socket.dart';
import '../../socket/socket_channels.dart';
import 'contact_request_event_types.dart';

class ContactRequestService {
  Future<dynamic> createContactRequest(ContactRequest cRequest) {
    return ChatSocket.instance.emitWAck(SocketChannelTypes.contactRequest,
        ContactRequestEventTypes.createContactRequests, cRequest.toJson());
  }

  Future<dynamic> acceptContactRequest(ContactRequest cRequest) {
    return ChatSocket.instance.emitWAck(SocketChannelTypes.contactRequest,
        ContactRequestEventTypes.acceptContactRequest, cRequest.uid);
  }

  Future<dynamic> cancelContactReqeuest(ContactRequest cRequest) {
    return ChatSocket.instance.emitWAck(SocketChannelTypes.contactRequest,
        ContactRequestEventTypes.cancelContactRequest, cRequest.uid);
  }

  Future<dynamic> declineContactRequest(ContactRequest cRequest) {
    return ChatSocket.instance.emitWAck(SocketChannelTypes.contactRequest,
        ContactRequestEventTypes.declineContactRequest, cRequest.uid);
  }

  void syncContactRequests(List<ContactRequest> contactRequests) async {
    final isar = Isar.getInstance() ??
        await Isar.open(
          [ContactRequestSchema],
          directory: '',
        );

    final List<ContactRequest> contactRequestsInDb =
        await isar.contactRequests.where().findAll();

    final List<ContactRequest> contactRequestsToPut = contactRequests
        .where((element) => contactRequestsInDb
            .where((dbEl) => dbEl.uid == element.uid)
            .isEmpty)
        .toList();

    await isar.writeTxn(() async {
      await isar.contactRequests.putAll(contactRequestsToPut);
    });
  }
}
