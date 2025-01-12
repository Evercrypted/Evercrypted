import 'dart:async';
import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/objectbox.g.dart';

import '../../socket/socket.dart';
import '../../socket/socket_channels.dart';
import '../contact/contact_service.dart';
import '../../socket/event_types/contact_request_event_types.dart';
import 'package:evercrypted/main.dart';

class ContactRequestService {
  final ContactService contactService = ContactService();

  findByUid(String uid) {
    final query =
        obx.contactRequests.query(ContactRequest_.uid.equals(uid)).build();
    final ContactRequest? contactRequest = query.findFirst();
    query.close();
    return contactRequest;
  }

  Future<dynamic> createContactRequest(ContactRequest cRequest) {
    return ChatSocket.emitWAck(SocketChannelTypes.contactRequest,
            ContactRequestEventTypes.createContactRequests, cRequest.toJson())
        .then((resp) {
      final ContactRequest returnedContactRequest =
          ContactRequest.fromJson(resp);
      returnedContactRequest.unread = false;
      syncContactRequests([returnedContactRequest]);
    });
  }

  Future<dynamic> acceptContactRequest(ContactRequest cRequest) {
    return ChatSocket.emitWAck(SocketChannelTypes.contactRequest,
            ContactRequestEventTypes.acceptContactRequest, cRequest.uid)
        .then((value) {
      obx.contacts.put(Contact.fromJson(value));
      obx.contactRequests.remove(cRequest.id);
    }).onError((error, stackTrace) {
      if (error == 'No such contact request found') {
        obx.contactRequests.remove(cRequest.id);
      }
    });
  }

  Future<dynamic> cancelContactReqeuest(ContactRequest cRequest) {
    return ChatSocket.emitWAck(SocketChannelTypes.contactRequest,
            ContactRequestEventTypes.cancelContactRequest, cRequest.uid)
        .then((value) {
      deleteContactRequest(cRequest.uid!);
    }).onError((error, stackTrace) {
      deleteContactRequest(cRequest.uid!);
    });
  }

  Future<dynamic> declineContactRequest(ContactRequest cRequest) {
    return ChatSocket.emitWAck(SocketChannelTypes.contactRequest,
            ContactRequestEventTypes.declineContactRequest, cRequest.uid)
        .then((value) {
      deleteContactRequest(cRequest.uid!);
    }).onError((error, stackTrace) {
      if (error == 'No such contact request found') {
        deleteContactRequest(cRequest.uid!);
      }
    });
  }

  deleteContactRequest(String uid) {
    final crInDb = findByUid(uid);
    if (crInDb != null) {
      obx.contactRequests.remove(crInDb.id);
    }
  }

  updateUnread(ContactRequest cRequest) {
    final crInDb = findByUid(cRequest.uid!);
    if (crInDb != null) {
      cRequest.id = crInDb.id;
      obx.contactRequests.put(cRequest);
    }
  }

  void syncContactRequests(List<ContactRequest> contactRequests) {
    final List<ContactRequest> contactRequestsInDb =
        obx.contactRequests.getAll();

    final List<ContactRequest> contactRequestsToPut = contactRequests
        .where((element) => contactRequestsInDb
            .where((dbEl) => dbEl.uid == element.uid)
            .isEmpty)
        .toList();

    final List<int> contactRequestsToDelete = contactRequestsInDb
        .where((element) =>
            contactRequests.where((el) => el.uid == element.uid).isEmpty)
        .map((ContactRequest el) => el.id)
        .toList();

    obx.contactRequests.removeMany(contactRequestsToDelete);
    obx.contactRequests.putMany(contactRequestsToPut);
  }
}
