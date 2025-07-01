import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/event_types/contact_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/objectbox.g.dart';

import 'contact_model.dart';

class ContactService {
  Contact? findContactByUid(String uid) {
    final query = obx.contacts.query(Contact_.uid.equals(uid)).build();
    final Contact? contact = query.findFirst();
    query.close();
    return contact;
  }

  void createContactAndRemoveContactRequest(
      Contact contact, String contactRequestUid) async {
    obx.contacts.put(contact);
    final query = obx.contactRequests
        .query(ContactRequest_.uid.equals(contactRequestUid))
        .build();
    final ContactRequest? crInDB = query.findFirst();
    query.close();
    if (crInDB != null) {
      obx.contactRequests.remove(crInDB.id);
    }
  }

  void deleteContact(String contactUid) async {
    return AppHttpClient.message(
      channel: SocketChannelTypes.contact,
      type: ContactEventTypes.deleteContact,
      payload: {'contactUid': contactUid},
    ).then((value) {
      final contact = findContactByUid(contactUid);
      if (contact != null) {
        obx.contacts.remove(contact.id);
      }
    });
  }

  void handleDeletedContact(String contactUid) {
    final contact = findContactByUid(contactUid);
    if (contact != null) {
      obx.contacts.remove(contact.id);
    }
  }

  void renameContact(String contactUid, String newName) async {
    final contact = findContactByUid(contactUid);
    if (contact == null) {
      return;
    } else {
      contact.name = newName;
      obx.contacts.put(contact);
    }
  }

  void syncContacts(List<Contact> contacts) async {
    final List<Contact> contactsInDb = obx.contacts.getAll();

    final List<Contact> contactsToPut = contacts
        .where((element) =>
            contactsInDb.where((dbEl) => dbEl.uid == element.uid).isEmpty)
        .toList();

    final List<int> contactsToDelete = contactsInDb
        .where(
            (element) => contacts.where((el) => el.uid == element.uid).isEmpty)
        .map((e) => e.id)
        .toList();

    obx.contacts.removeMany(contactsToDelete);
    obx.contacts.putMany(contactsToPut);
  }

  toggleFavorite(String contactUid) async {
    AppHttpClient.message(
      channel: SocketChannelTypes.contact,
      type: ContactEventTypes.toggleFavorite,
      payload: {'contactUid': contactUid},
    ).then((resp) async {
      final contact = findContactByUid(contactUid);
      if (contact != null) {
        contact.isFavorite = !contact.isFavorite;
        obx.contacts.put(contact);
      }
    });
  }
}
