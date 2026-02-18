import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/http.dart';
import 'package:evercrypted/core/socket/event_types/contact_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/core/obx_init.dart';
import 'package:evercrypted/objectbox.g.dart';
import 'package:collection/collection.dart';

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
      contact.customName = newName;
      ObxInit.obx.contacts.put(contact);

      // Update participant name in all chats with this contact
      final chats = ObxInit.obx.chats.getAll();
      for (final chat in chats) {
        bool updated = false;
        final updatedParticipants = chat.participants.map((p) {
          if (p.uid == contact.contactPersonUid) {
            updated = true;
            return p.copyWith(name: contact.displayName);
          }
          return p;
        }).toList();

        if (updated) {
          chat.participants = updatedParticipants;
          ObxInit.obx.chats.put(chat);
        }
      }
    }
  }

  void syncContacts(List<Contact> contacts) async {
    final List<Contact> contactsInDb = ObxInit.obx.contacts.getAll();

    // Contacts to add (new contacts not in DB)
    final List<Contact> contactsToAdd = contacts
        .where((element) =>
            contactsInDb.where((dbEl) => dbEl.uid == element.uid).isEmpty)
        .toList();

    // Contacts to update (existing contacts with potentially new data)
    final List<Contact> contactsToUpdate = [];
    for (final serverContact in contacts) {
      final existingContact = contactsInDb.firstWhereOrNull(
        (dbContact) => dbContact.uid == serverContact.uid,
      );
      if (existingContact != null) {
        // Update existing contact with fresh data from server
        // Note: We preserve customName - only update the actual profile data
        existingContact.name = serverContact.name;
        existingContact.email = serverContact.email;
        existingContact.avatar = serverContact.avatar;
        existingContact.isFavorite = serverContact.isFavorite;
        // customName is NOT updated - it's a local preference
        contactsToUpdate.add(existingContact);
      }
    }

    // Contacts to delete (in DB but not on server)
    final List<int> contactsToDelete = contactsInDb
        .where(
            (element) => contacts.where((el) => el.uid == element.uid).isEmpty)
        .map((e) => e.id)
        .toList();

    // Apply all changes
    ObxInit.obx.contacts.removeMany(contactsToDelete);
    ObxInit.obx.contacts.putMany([...contactsToAdd, ...contactsToUpdate]);
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
