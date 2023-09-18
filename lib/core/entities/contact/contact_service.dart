import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/socket/chat_socket.dart';
import 'package:evercrypted/core/socket/event_types/contact_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:isar/isar.dart';

import 'contact_model.dart';

class ContactService {
  void createContactAndRemoveContactRequest(
      Contact contact, String contactRequestUid) async {
    final isar = Isar.getInstance();

    await isar?.writeTxn(() async {
      await isar.contacts.put(contact);
      await isar.contactRequests.deleteByUid(contactRequestUid);
    });
  }

  void deleteContact(String contactUid) async {
    final isar = Isar.getInstance();
    return ChatSocket.instance
        .emitWAck(SocketChannelTypes.contact, ContactEventTypes.deleteContact,
            contactUid)
        .then((value) {
      isar?.writeTxn(() async {
        isar.contacts.deleteByUid(contactUid);
      });
    }).onError((error, stackTrace) {
      if (error == 'No such contact found') {
        isar?.writeTxn(() async {
          isar.contacts.deleteByUid(contactUid);
        });
      }
    });
  }

  void syncContacts(List<Contact> contacts) async {
    final isar = Isar.getInstance();

    final List<Contact> contactsInDb = await isar!.contacts.where().findAll();

    final List<Contact> contactsToPut = contacts
        .where((element) =>
            contactsInDb.where((dbEl) => dbEl.uid == element.uid).isEmpty)
        .toList();

    await isar.writeTxn(() async {
      await isar.contacts.putAll(contactsToPut);
    });
  }
}
