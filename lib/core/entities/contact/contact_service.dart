import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/fernet.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/core/socket/event_types/contact_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:isar/isar.dart';

import 'contact_model.dart';

class ContactService {
  void createContactAndRemoveContactRequest(
      Contact contact, String contactRequestUid) async {
    final isar = Isar.getInstance();

    final String appKey = await Auth.getAppKey;

    final Contact toPut = contact.copyWith(
        email: fernetEncrypt(contact.email, appKey),
        name: fernetEncrypt(contact.name, appKey));

    await isar?.writeTxn(() async {
      await isar.contacts.put(toPut);
      await isar.contactRequests.deleteByUid(contactRequestUid);
    });
  }

  void deleteContact(String contactUid) async {
    final isar = Isar.getInstance();
    return ChatSocket.emitWAck(
        SocketChannelTypes.contact,
        ContactEventTypes.deleteContact,
        {'contactUid': contactUid}).then((value) {
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

  void handleDeletedContact(String contactUid) {
    final isar = Isar.getInstance();
    isar?.writeTxn(() async {
      isar.contacts.deleteByUid(contactUid);
    });
  }

  void renameContact(String contactUid, String newName) async {
    final isar = Isar.getInstance();

    final String appKey = await Auth.getAppKey;

    await isar?.writeTxn(() async {
      final contact =
          await isar.contacts.where().uidEqualTo(contactUid).findFirst();
      contact?.name = newName;
      contact?.name = fernetEncrypt(newName, appKey);
      await isar.contacts.put(contact!);
    });
  }

  void syncContacts(List<Contact> contacts) async {
    final isar = Isar.getInstance();

    final List<Contact> contactsInDb = await isar!.contacts.where().findAll();

    final List<Contact> contactsToPut = contacts
        .where((element) =>
            contactsInDb.where((dbEl) => dbEl.uid == element.uid).isEmpty)
        .toList();

    final List<int> contactsToDelete = contactsInDb
        .where(
            (element) => contacts.where((el) => el.uid == element.uid).isEmpty)
        .map((e) => e.id)
        .toList();

    final String appKey = await Auth.getAppKey;

    final toPut = contactsToPut
        .map((contact) => contact.copyWith(
            email: fernetEncrypt(contact.email, appKey),
            name: fernetEncrypt(contact.name, appKey)))
        .toList();

    await isar.writeTxn(() async {
      await isar.contacts.putAll(toPut);
      await isar.contacts.deleteAll(contactsToDelete);
    });
  }

  toggleFavorite(String contactUid) async {
    ChatSocket.emitWAck(
        SocketChannelTypes.contact,
        ContactEventTypes.toggleFavorite,
        {'contactUid': contactUid}).then((resp) async {
      final isar = Isar.getInstance();
      final contact =
          await isar?.contacts.where().uidEqualTo(contactUid).findFirst();
      contact?.isFavorite = !contact.isFavorite;
      await isar?.writeTxn(() async {
        await isar.contacts.put(contact!);
      });
    });
  }
}
