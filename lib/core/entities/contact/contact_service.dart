import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/socket/event_types/contact_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/core/obx_init.dart';
import 'package:evercrypted/objectbox.g.dart';

import 'contact_model.dart';

class ContactService {
  Contact? findContactByUid(String uid) {
    final query = ObxInit.obx.contacts.query(Contact_.uid.equals(uid)).build();
    final Contact? contact = query.findFirst();
    query.close();
    return contact;
  }

  void createContactAndRemoveContactRequest(
      Contact contact, String contactRequestUid) async {
    ObxInit.obx.contacts.put(contact);
    final query = ObxInit.obx.contactRequests
        .query(ContactRequest_.uid.equals(contactRequestUid))
        .build();
    final ContactRequest? crInDB = query.findFirst();
    query.close();
    if (crInDB != null) {
      ObxInit.obx.contactRequests.remove(crInDB.id);
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
        ObxInit.obx.contacts.remove(contact.id);
      }
    });
  }

  void handleDeletedContact(String contactUid) {
    final contact = findContactByUid(contactUid);
    if (contact != null) {
      ObxInit.obx.contacts.remove(contact.id);
    }
  }

  void renameContact(String contactUid, String newName) async {
    final contact = findContactByUid(contactUid);
    if (contact == null) {
      return;
    } else {
      contact.name = newName;
      ObxInit.obx.contacts.put(contact);
    }
  }

  void syncContacts(List<Contact> contacts) async {
    final List<Contact> contactsInDb = ObxInit.obx.contacts.getAll();

    final List<Contact> contactsToPut = contacts
        .where((element) =>
            contactsInDb.where((dbEl) => dbEl.uid == element.uid).isEmpty)
        .toList();

    final List<int> contactsToDelete = contactsInDb
        .where(
            (element) => contacts.where((el) => el.uid == element.uid).isEmpty)
        .map((e) => e.id)
        .toList();

    ObxInit.obx.contacts.removeMany(contactsToDelete);
    ObxInit.obx.contacts.putMany(contactsToPut);
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
        ObxInit.obx.contacts.put(contact);
      }
    });
  }
}
