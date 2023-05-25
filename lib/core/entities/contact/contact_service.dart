import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
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
