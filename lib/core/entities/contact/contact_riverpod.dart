import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'contact_model.dart';

class ContactsNotifier extends StateNotifier<List<Contact>> {
  // We initialize the list of todos to an empty list
  ContactsNotifier() : super([]);

  void setContacts(List<Contact> contacts) {
    state = [...contacts];
  }

  void addContact(Contact contact) {
    state = [contact, ...state];
  }
}

final contactsProvider =
    StateNotifierProvider<ContactsNotifier, List<Contact>>((ref) {
  return ContactsNotifier();
});
