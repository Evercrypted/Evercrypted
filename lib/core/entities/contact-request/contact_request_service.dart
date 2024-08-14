import 'dart:async';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/fernet.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:isar/isar.dart';

import '../../socket/socket.dart';
import '../../socket/socket_channels.dart';
import '../contact/contact_service.dart';
import '../../socket/event_types/contact_request_event_types.dart';

class ContactRequestService {
  final ContactService contactService = ContactService();

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

  Future<dynamic> acceptContactRequest(ContactRequest cRequest) async {
    final isar = Isar.getInstance();
    final String appKey = await Auth.getAppKey;

    return ChatSocket.emitWAck(SocketChannelTypes.contactRequest,
            ContactRequestEventTypes.acceptContactRequest, cRequest.uid)
        .then((value) {
      isar?.writeTxn(() async {
        isar.contactRequests.deleteByUid(cRequest.uid);
        isar.contacts.put(Contact.fromJson(value).copyWith(
            email: fernetEncrypt(Contact.fromJson(value).email, appKey),
            name: fernetEncrypt(Contact.fromJson(value).name, appKey)));
      });
    }).onError((error, stackTrace) {
      if (error == 'No such contact request found') {
        isar?.writeTxn(() async {
          isar.contactRequests.deleteByUid(cRequest.uid);
        });
      }
    });
  }

  Future<dynamic> cancelContactReqeuest(ContactRequest cRequest) {
    final isar = Isar.getInstance();
    return ChatSocket.emitWAck(SocketChannelTypes.contactRequest,
            ContactRequestEventTypes.cancelContactRequest, cRequest.uid)
        .then((value) {
      isar?.writeTxn(() async {
        isar.contactRequests.deleteByUid(cRequest.uid);
      });
    }).onError((error, stackTrace) {
      if (error == 'No such contact request found') {
        isar?.writeTxn(() async {
          isar.contactRequests.deleteByUid(cRequest.uid);
        });
      }
    });
  }

  Future<dynamic> declineContactRequest(ContactRequest cRequest) {
    final isar = Isar.getInstance();
    return ChatSocket.emitWAck(SocketChannelTypes.contactRequest,
            ContactRequestEventTypes.declineContactRequest, cRequest.uid)
        .then((value) {
      isar?.writeTxn(() async {
        isar.contactRequests.deleteByUid(cRequest.uid);
      });
    }).onError((error, stackTrace) {
      if (error == 'No such contact request found') {
        isar?.writeTxn(() async {
          isar.contactRequests.deleteByUid(cRequest.uid);
        });
      }
    });
  }

  deleteContactRequest(String uid) {
    final isar = Isar.getInstance();
    isar?.writeTxn(() async {
      isar.contactRequests.deleteByUid(uid);
    });
  }

  updateUnread(ContactRequest cRequest) {
    final isar = Isar.getInstance();
    isar?.writeTxn(() async {
      isar.contactRequests.putByUid(cRequest);
    });
  }

  void syncContactRequests(List<ContactRequest> contactRequests) async {
    final isar = Isar.getInstance();

    final String appKey = await Auth.getAppKey;

    final List<ContactRequest> contactRequestsInDb =
        await isar!.contactRequests.where().findAll();

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

    final toPut = contactRequestsToPut.map((e) {
      return e.copyWith(
          authorEmail: fernetEncrypt(e.authorEmail, appKey),
          recipientEmail: fernetEncrypt(e.recipientEmail, appKey),
          message: fernetEncrypt(e.message, appKey));
    }).toList();

    await isar.writeTxn(() async {
      await isar.contactRequests.putAll(toPut);
      await isar.contactRequests.deleteAll(contactRequestsToDelete);
    });
  }
}
